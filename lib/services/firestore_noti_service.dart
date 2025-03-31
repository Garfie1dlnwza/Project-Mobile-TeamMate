import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:flutter/foundation.dart';

class FirestoreNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreUserService _userService = FirestoreUserService();

  // Singleton pattern
  static final FirestoreNotificationService _instance =
      FirestoreNotificationService._internal();

  factory FirestoreNotificationService() {
    return _instance;
  }

  FirestoreNotificationService._internal();

  // ดึงการแจ้งเตือนของผู้ใช้ปัจจุบัน
  Stream<QuerySnapshot> getUserNotifications() {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      return _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      // ถ้าไม่มีผู้ใช้ที่เข้าสู่ระบบ จะคืนค่า stream ว่าง
      return Stream.empty();
    }
  }

  // ดึงการแจ้งเตือนของผู้ใช้ที่ยังไม่ได้อ่าน
  Stream<QuerySnapshot> getUnreadNotifications() {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      return _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      // ถ้าไม่มีผู้ใช้ที่เข้าสู่ระบบ จะคืนค่า stream ว่าง
      return Stream.empty();
    }
  }

  // ทำเครื่องหมายว่าอ่านแล้ว
  Future<void> markAsRead(String notificationId) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      // ตรวจสอบว่ายังมีการแจ้งเตือนที่ยังไม่ได้อ่านหรือไม่
      await _updateUserUnreadStatus(currentUser.uid);
    }
  }

  // ทำเครื่องหมายว่าอ่านทั้งหมดแล้ว
  Future<void> markAllAsRead() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      // ดึงการแจ้งเตือนที่ยังไม่ได้อ่านทั้งหมด
      final QuerySnapshot unreadNotifications =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('notifications')
              .where('read', isEqualTo: false)
              .get();

      // ใช้ Batch Write เพื่อทำเครื่องหมายว่าอ่านแล้วพร้อมกัน
      final WriteBatch batch = _firestore.batch();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      // ยืนยันการทำเครื่องหมายทั้งหมด
      await batch.commit();

      // อัปเดตสถานะการแจ้งเตือนที่ยังไม่ได้อ่านของผู้ใช้
      await _userService.updateUnreadNotificationStatus(currentUser.uid, false);
    }
  }

  // อัปเดตสถานะการแจ้งเตือนที่ยังไม่ได้อ่านของผู้ใช้
  Future<void> _updateUserUnreadStatus(String userId) async {
    final int unreadCount = await getUnreadNotificationCount();
    await _userService.updateUnreadNotificationStatus(userId, unreadCount > 0);
  }

  // ลบการแจ้งเตือน
  Future<void> deleteNotification(String notificationId) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // ตรวจสอบสถานะการแจ้งเตือนที่ยังไม่ได้อ่าน
      await _updateUserUnreadStatus(currentUser.uid);
    }
  }

  // สร้างการแจ้งเตือนใหม่
  Future<void> createNotification({
    required String userId,
    required String type,
    required String message,
    String? projectId,
    String? taskId,
    String? pollId,
    String? postId,
    String? documentId,
    String? senderId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // ข้อมูลพื้นฐานของการแจ้งเตือน
      Map<String, dynamic> notificationData = {
        'type': type,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // เพิ่ม fields ตามประเภทของการแจ้งเตือน
      if (projectId != null) notificationData['projectId'] = projectId;
      if (taskId != null) notificationData['taskId'] = taskId;
      if (pollId != null) notificationData['pollId'] = pollId;
      if (postId != null) notificationData['postId'] = postId;
      if (documentId != null) notificationData['documentId'] = documentId;
      if (senderId != null) notificationData['senderId'] = senderId;

      // เพิ่มข้อมูลเพิ่มเติม (ถ้ามี)
      if (additionalData != null) {
        notificationData.addAll(additionalData);
      }

      // เพิ่มการแจ้งเตือนให้กับผู้ใช้
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notificationData);

      // อัปเดตสถานะการแจ้งเตือนที่ยังไม่ได้อ่านของผู้ใช้
      await _userService.updateUnreadNotificationStatus(userId, true);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating notification: $e');
      }
      rethrow;
    }
  }

  // ส่งการแจ้งเตือนเมื่อมีการเชิญเข้าร่วมโปรเจค
  Future<void> sendProjectInvitation({
    required String userId,
    required String projectId,
    required String projectName,
    required String inviterName,
  }) async {
    final String message =
        '$inviterName invited you to join $projectName project';

    await createNotification(
      userId: userId,
      type: 'project_invitation',
      message: message,
      projectId: projectId,
      senderId: _auth.currentUser?.uid,
      additionalData: {'projectName': projectName, 'inviterName': inviterName},
    );
  }

  // ส่งการแจ้งเตือนเมื่อมีการสร้างงานใหม่
  Future<void> sendTaskCreatedNotification({
    required String userId,
    required String taskId,
    required String taskTitle,
    required String creatorName,
    String? projectId,
  }) async {
    final String message = '$creatorName created a new task: $taskTitle';

    await createNotification(
      userId: userId,
      type: 'task_created',
      message: message,
      taskId: taskId,
      projectId: projectId,
      senderId: _auth.currentUser?.uid,
      additionalData: {'taskTitle': taskTitle, 'creatorName': creatorName},
    );
  }

  // ส่งการแจ้งเตือนเมื่อมีการส่งงาน
  Future<void> sendTaskSubmittedNotification({
    required String userId,
    required String taskId,
    required String taskTitle,
    required String submitterName,
    String? projectId,
  }) async {
    final String message = '$submitterName submitted task: $taskTitle';

    await createNotification(
      userId: userId,
      type: 'task_submitted',
      message: message,
      taskId: taskId,
      projectId: projectId,
      senderId: _auth.currentUser?.uid,
      additionalData: {'taskTitle': taskTitle, 'submitterName': submitterName},
    );
  }

  // ส่งการแจ้งเตือนเมื่องานได้รับการอนุมัติ
  Future<void> sendTaskApprovedNotification({
    required String userId,
    required String taskId,
    required String taskTitle,
    required String approverName,
    String? projectId,
  }) async {
    final String message = '$approverName approved your task: $taskTitle';

    await createNotification(
      userId: userId,
      type: 'task_approved',
      message: message,
      taskId: taskId,
      projectId: projectId,
      senderId: _auth.currentUser?.uid,
      additionalData: {'taskTitle': taskTitle, 'approverName': approverName},
    );
  }

  // ส่งการแจ้งเตือนเมื่องานถูกปฏิเสธ
  Future<void> sendTaskRejectedNotification({
    required String userId,
    required String taskId,
    required String taskTitle,
    required String rejecterName,
    String? projectId,
    String? rejectionReason,
  }) async {
    final String message = '$rejecterName rejected your task: $taskTitle';

    await createNotification(
      userId: userId,
      type: 'task_rejected',
      message: message,
      taskId: taskId,
      projectId: projectId,
      senderId: _auth.currentUser?.uid,
      additionalData: {
        'taskTitle': taskTitle,
        'rejecterName': rejecterName,
        'rejectionReason': rejectionReason,
      },
    );
  }

  // ส่งการแจ้งเตือนเมื่อมีการอัปเดตงาน
  Future<void> sendTaskUpdatedNotification({
    required String userId,
    required String taskId,
    required String taskTitle,
    required String updaterName,
    String? projectId,
    String? updateDetails,
  }) async {
    final String message = '$updaterName updated task: $taskTitle';

    await createNotification(
      userId: userId,
      type: 'task_updated',
      message: message,
      taskId: taskId,
      projectId: projectId,
      senderId: _auth.currentUser?.uid,
      additionalData: {
        'taskTitle': taskTitle,
        'updaterName': updaterName,
        'updateDetails': updateDetails,
      },
    );
  }

  // ส่งการแจ้งเตือนเมื่อมีการสร้างโพลใหม่
  Future<void> sendPollCreatedNotification({
    required String userId,
    required String pollId,
    required String pollQuestion,
    required String creatorName,
    String? projectId,
  }) async {
    final String message = '$creatorName created a new poll: $pollQuestion';

    await createNotification(
      userId: userId,
      type: 'poll_created',
      message: message,
      pollId: pollId,
      projectId: projectId,
      senderId: _auth.currentUser?.uid,
      additionalData: {
        'pollQuestion': pollQuestion,
        'creatorName': creatorName,
      },
    );
  }

  // ส่งการแจ้งเตือนเมื่อมีการสร้างโพสต์ใหม่
  Future<void> sendPostCreatedNotification({
    required String userId,
    required String postId,
    required String postTitle,
    required String creatorName,
    String? projectId,
  }) async {
    final String message = '$creatorName created a new post: $postTitle';

    await createNotification(
      userId: userId,
      type: 'post_created',
      message: message,
      postId: postId,
      projectId: projectId,
      senderId: _auth.currentUser?.uid,
      additionalData: {'postTitle': postTitle, 'creatorName': creatorName},
    );
  }

  // ส่งการแจ้งเตือนเมื่อมีคนแสดงความคิดเห็นในโพสต์
  Future<void> sendPostCommentNotification({
    required String userId,
    required String postId,
    required String postTitle,
    required String commenterName,
    String? projectId,
    String? commentText,
  }) async {
    final String message = '$commenterName commented on your post: $postTitle';

    await createNotification(
      userId: userId,
      type: 'post_comment',
      message: message,
      postId: postId,
      projectId: projectId,
      senderId: _auth.currentUser?.uid,
      additionalData: {
        'postTitle': postTitle,
        'commenterName': commenterName,
        'commentText': commentText,
      },
    );
  }

  // ส่งการแจ้งเตือนเมื่อมีการแชร์เอกสาร
  Future<void> sendDocumentSharedNotification({
    required String departmentId,
    required String documentId,
    required String documentTitle,
    required String sharerName,
    required String projectId,
  }) async {
    try {
      await sendNotificationToDepartmentMembers(
        departmentId: departmentId,
        type: 'document_shared',
        message: '$sharerName shared a new document: $documentTitle',
        additionalData: {
          'documentId': documentId,
          'documentTitle': documentTitle,
          'sharerName': sharerName,
          'projectId': projectId,
        },
      );
    } catch (e) {
      debugPrint('Error sending document notification: $e');
    }
  }

  // นับจำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน
  Future<int> getUnreadNotificationCount() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('notifications')
              .where('read', isEqualTo: false)
              .get();

      return snapshot.docs.length;
    }

    return 0;
  }

  // ดึงจำนวนการแจ้งเตือนที่ยังไม่ได้อ่านแบบ Stream (สำหรับแสดงแบบเรียลไทม์)
  Stream<int> getUnreadNotificationCountStream() {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      return _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    }

    return Stream.value(0);
  }

  // ลบการแจ้งเตือนที่เก่า
  Future<void> deleteOldNotifications(int olderThanDays) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // คำนวณวันที่ที่ใช้เป็นเกณฑ์
      final DateTime threshold = DateTime.now().subtract(
        Duration(days: olderThanDays),
      );
      final Timestamp thresholdTimestamp = Timestamp.fromDate(threshold);

      // ดึงการแจ้งเตือนที่เก่ากว่าเกณฑ์
      final QuerySnapshot oldNotifications =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('notifications')
              .where('timestamp', isLessThan: thresholdTimestamp)
              .get();

      // ใช้ Batch Write เพื่อลบการแจ้งเตือนพร้อมกัน
      if (oldNotifications.docs.isNotEmpty) {
        final WriteBatch batch = _firestore.batch();

        for (var doc in oldNotifications.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        if (kDebugMode) {
          print('Deleted ${oldNotifications.docs.length} old notifications');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting old notifications: $e');
      }
    }
  }

  // ดึงการแจ้งเตือนตามประเภท
  Future<List<QueryDocumentSnapshot>> getNotificationsByType(
    String type,
  ) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('notifications')
              .where('type', isEqualTo: type)
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notifications by type: $e');
      }
      return [];
    }
  }

  // ส่งการแจ้งเตือนไปยังสมาชิกทุกคนในโปรเจค
  Future<void> sendNotificationToProjectMembers({
    required String projectId,
    required String type,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // ดึงข้อมูลโปรเจค
      final DocumentSnapshot projectDoc =
          await _firestore.collection('projects').doc(projectId).get();

      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      final Map<String, dynamic> projectData =
          projectDoc.data() as Map<String, dynamic>;

      // รวบรวมรายชื่อผู้ใช้ที่เกี่ยวข้องกับโปรเจค
      List<String> memberIds = [];

      // เพิ่มหัวหน้าโปรเจค (headId)
      if (projectData.containsKey('headId')) {
        if (projectData['headId'] is String) {
          memberIds.add(projectData['headId']);
        } else if (projectData['headId'] is List) {
          memberIds.addAll(List<String>.from(projectData['headId']));
        }
      }

      // ดึงรายชื่อแผนกในโปรเจค
      if (projectData.containsKey('departments') &&
          projectData['departments'] is List) {
        List<String> departmentIds = List<String>.from(
          projectData['departments'],
        );

        // ดึงสมาชิกจากทุกแผนก
        for (String departmentId in departmentIds) {
          final DocumentSnapshot departmentDoc =
              await _firestore
                  .collection('departments')
                  .doc(departmentId)
                  .get();

          if (departmentDoc.exists) {
            final Map<String, dynamic> departmentData =
                departmentDoc.data() as Map<String, dynamic>;

            // เพิ่มผู้ดูแลแผนก
            if (departmentData.containsKey('admins') &&
                departmentData['admins'] is List) {
              List<String> adminIds = List<String>.from(
                departmentData['admins'],
              );
              memberIds.addAll(adminIds);
            }

            // เพิ่มสมาชิกแผนก
            if (departmentData.containsKey('users') &&
                departmentData['users'] is List) {
              List<String> userIds = List<String>.from(departmentData['users']);
              memberIds.addAll(userIds);
            }
          }
        }
      }

      // กรองให้แต่ละ ID มีเพียงครั้งเดียว
      memberIds = memberIds.toSet().toList();

      // ส่งการแจ้งเตือนให้กับสมาชิกทุกคน (ยกเว้นผู้ใช้ปัจจุบัน)
      final String? currentUserId = _auth.currentUser?.uid;
      final String senderName =
          _auth.currentUser?.displayName ?? 'A team member';

      for (String memberId in memberIds) {
        // ข้ามตัวเองถ้าเป็นสมาชิกด้วย
        if (memberId == currentUserId) continue;

        // สร้างข้อมูลการแจ้งเตือน
        Map<String, dynamic> notificationData = {
          'type': type,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'projectId': projectId,
          'senderId': currentUserId,
        };

        // เพิ่มข้อมูลเพิ่มเติม (ถ้ามี)
        if (additionalData != null) {
          notificationData.addAll(additionalData);
        }

        // เพิ่มการแจ้งเตือนให้กับผู้ใช้
        await _firestore
            .collection('users')
            .doc(memberId)
            .collection('notifications')
            .add(notificationData);

        // อัปเดตสถานะการแจ้งเตือนที่ยังไม่ได้อ่านของผู้ใช้
        await _userService.updateUnreadNotificationStatus(memberId, true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification to project members: $e');
      }
      rethrow;
    }
  }

  // ส่งการแจ้งเตือนไปยังสมาชิกทุกคนในแผนก
  Future<void> sendNotificationToDepartmentMembers({
    required String departmentId,
    required String type,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // ดึงข้อมูลแผนก
      final DocumentSnapshot departmentDoc =
          await _firestore.collection('departments').doc(departmentId).get();

      if (!departmentDoc.exists) {
        throw Exception('Department not found');
      }

      final Map<String, dynamic> departmentData =
          departmentDoc.data() as Map<String, dynamic>;

      // รวบรวมรายชื่อผู้ใช้ที่เกี่ยวข้องกับแผนก
      List<String> memberIds = [];

      // เพิ่มผู้ดูแลแผนก
      if (departmentData.containsKey('admins') &&
          departmentData['admins'] is List) {
        List<String> adminIds = List<String>.from(departmentData['admins']);
        memberIds.addAll(adminIds);
      }

      // เพิ่มสมาชิกแผนก
      if (departmentData.containsKey('users') &&
          departmentData['users'] is List) {
        List<String> userIds = List<String>.from(departmentData['users']);
        memberIds.addAll(userIds);
      }

      // กรองให้แต่ละ ID มีเพียงครั้งเดียว
      memberIds = memberIds.toSet().toList();

      // ส่งการแจ้งเตือนให้กับสมาชิกทุกคน (ยกเว้นผู้ใช้ปัจจุบัน)
      final String? currentUserId = _auth.currentUser?.uid;
      final String senderName =
          _auth.currentUser?.displayName ?? 'A team member';

      for (String memberId in memberIds) {
        // ข้ามตัวเองถ้าเป็นสมาชิกด้วย
        if (memberId == currentUserId) continue;

        // สร้างข้อมูลการแจ้งเตือน
        Map<String, dynamic> notificationData = {
          'type': type,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'departmentId': departmentId,
          'senderId': currentUserId,
        };

        // เพิ่มข้อมูลเพิ่มเติม (ถ้ามี)
        if (additionalData != null) {
          notificationData.addAll(additionalData);
        }

        // เพิ่มการแจ้งเตือนให้กับผู้ใช้
        await _firestore
            .collection('users')
            .doc(memberId)
            .collection('notifications')
            .add(notificationData);

        // อัปเดตสถานะการแจ้งเตือนที่ยังไม่ได้อ่านของผู้ใช้
        await _userService.updateUnreadNotificationStatus(memberId, true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification to department members: $e');
      }
      rethrow;
    }
  }

  // ตรวจสอบการเปลี่ยนแปลงของจำนวนการแจ้งเตือนและอัปเดตสถานะผู้ใช้
  Future<void> syncNotificationStatusWithCount() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    int count = await getUnreadNotificationCount();
    bool hasUnread = count > 0;

    await _userService.updateUnreadNotificationStatus(
      currentUser.uid,
      hasUnread,
    );
  }

  // Get title for notification type
  String getNotificationTitle(String type) {
    switch (type) {
      case 'project_invitation':
        return 'Project Invitation';
      case 'task_created':
        return 'New Task';
      case 'task_updated':
        return 'Task Updated';
      case 'task_submitted':
        return 'Task Submitted';
      case 'task_approved':
        return 'Task Approved';
      case 'task_rejected':
        return 'Task Rejected';
      case 'poll_created':
        return 'New Poll';
      case 'post_created':
        return 'New Post';
      case 'post_comment':
        return 'New Comment';
      case 'document_shared':
        return 'Document Shared';
      default:
        return 'Notification';
    }
  }
}
