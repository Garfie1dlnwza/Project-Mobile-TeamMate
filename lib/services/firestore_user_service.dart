import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreUserService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // สร้างหรืออัปเดตผู้ใช้
  Future<void> createOrUpdateUser(
    String userId,
    String name,
    String email, {
    List<String>? projectIds,
    String? notiId,
  }) async {
    try {
      await _usersCollection.doc(userId).set({
        'uid': userId,
        'name': name,
        'email': email,
        'projectIds': projectIds ?? [],
        'notiId': notiId,
        'lastLogin': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error creating or updating user: $e");
      rethrow;
    }
  }

  // ดึงข้อมูลผู้ใช้โดย ID
  Future<DocumentSnapshot> getUserById(String userId) async {
    try {
      return await _usersCollection.doc(userId).get();
    } catch (e) {
      print("Error getting user by ID: $e");
      rethrow;
    }
  }

  // หาชื่อผู้ใช้จาก ID
  Future<String?> findNameById(String id) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(id).get();
      if (!userDoc.exists) {
        print("User not found for ID: $id");
        return null;
      }
      
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      return data?['name'] as String?;
    } catch (e) {
      print("Error finding user by ID: $e");
      return null;
    }
  }

  // ดึงรายการโปรเจคของผู้ใช้
  Future<List<String>> getUserProjects(String userId) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('projectIds')) {
          return List<String>.from(data['projectIds'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print("Error getting user projects: $e");
      return [];
    }
  }

  // เพิ่มโปรเจคให้กับผู้ใช้
  Future<void> addProjectToUser(String projectId, String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'projectIds': FieldValue.arrayUnion([projectId]),
      });
      print("Project $projectId added successfully to user $userId");
    } catch (e) {
      print("Error adding project to user: $e");
      rethrow;
    }
  }

  // เพิ่มโปรเจคทั้งชุดให้กับผู้ใช้ (deprecate this and use addProjectToUser instead)
  Future<void> updateUserProjects(String userId, String projectId) async {
    try {
      await addProjectToUser(projectId, userId);
    } catch (e) {
      print("Error updating user projects: $e");
      rethrow;
    }
  }

  // ดึง Notification ID ของผู้ใช้
  Future<String?> getUserNotiId(String userId) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        return data?['notiId'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting notification ID: $e");
      return null;
    }
  }

  // อัปเดต Notification ID ของผู้ใช้
  Future<void> updateUserNotiId(String userId, String notiId) async {
    try {
      await _usersCollection.doc(userId).update({'notiId': notiId});
    } catch (e) {
      print("Error updating notification ID: $e");
      rethrow;
    }
  }

  // หา User ID จากอีเมล
  Future<String?> getUserIdByEmail(String email) async {
    try {
      // Query the users collection to find a user with the matching email
      QuerySnapshot querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // If a user is found, return their user ID
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      // Return null if no user is found with the given email
      return null;
    } catch (e) {
      print("Error retrieving user ID by email: $e");
      return null;
    }
  }
}