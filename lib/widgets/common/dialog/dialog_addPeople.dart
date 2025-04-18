import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_noti_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/theme/app_colors.dart';

class AddPeopleDialog extends StatefulWidget {
  final String title;
  final String projectId;
  final String departmentId;

  const AddPeopleDialog({
    super.key,
    required this.title,
    required this.projectId,
    required this.departmentId,
  });

  @override
  State<AddPeopleDialog> createState() => _AddPeopleDialogState();
}

class _AddPeopleDialogState extends State<AddPeopleDialog> {
  final TextEditingController _emailController = TextEditingController();
  final FirestoreUserService _userService = FirestoreUserService();
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();
  final FirestoreProjectService _projectService = FirestoreProjectService();
  final FirestoreNotificationService _notificationService =
      FirestoreNotificationService(); // เพิ่มบริการแจ้งเตือน

  String? _currentUserId;
  bool _isLoading = false;
  DocumentSnapshot? _departmentData;
  String? _departmentName;
  String? _projectName;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadDepartmentData();
    _loadProjectData();
  }

  Future<void> _loadDepartmentData() async {
    try {
      _departmentData = await _departmentService.getDepartmentById(
        widget.departmentId,
      );

      // เก็บชื่อแผนก
      if (_departmentData != null && _departmentData!.exists) {
        final Map<String, dynamic> data =
            _departmentData!.data() as Map<String, dynamic>;
        setState(() {
          _departmentName = data['name'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading department data: $e')),
        );
      }
    }
  }

  // เพิ่มเมธอดใหม่: โหลดข้อมูลโปรเจค
  Future<void> _loadProjectData() async {
    try {
      final projectDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(widget.projectId)
              .get();

      if (projectDoc.exists) {
        final projectData = projectDoc.data() as Map<String, dynamic>;
        setState(() {
          _projectName = projectData['name'];
        });
      }
    } catch (e) {
      print('Error loading project data: $e');
    }
  }

  Future<void> _addPeople() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an email')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch user ID by email
      final userId = await _userService.getUserIdByEmail(_emailController.text);
      print('User ID : $userId');
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user found with this email')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check authorization
      bool isHead = await _projectService.isUserHeadOfProject(
        widget.projectId,
        _currentUserId!,
      );
      // print(isHead);
      bool isAdmin = await _departmentService.isUserAdminOfDepartment(
        widget.departmentId,
        _currentUserId!,
      );

      if (!isHead && !isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are not authorized to add people'),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
      print('departmentData: $_departmentData');

      // Check if user is admin so : don't add to users
      List<dynamic> adminList = _departmentData?['admins'] ?? [];
      if (adminList.contains(userId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This user is already in admins')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check if user is already in the department
      List<dynamic> userList = _departmentData?['users'] ?? [];
      if (userList.contains(userId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This user is already in this department'),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Add user to department
      await _departmentService.addUserToDepartment(
        departmentId: widget.departmentId,
        userId: userId,
      );

      // Add the Project to User
      await _userService.addProjectToUser(widget.projectId, userId);

      // ส่งการแจ้งเตือนให้ผู้ใช้ที่ถูกเพิ่ม
      await _sendNotificationsToAddedUser(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _emailController.clear();
        Navigator.of(context).pop(true); // Close dialog with success result
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding user: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // เมธอดใหม่: ส่งการแจ้งเตือนให้ผู้ใช้ที่ถูกเพิ่ม
  Future<void> _sendNotificationsToAddedUser(String userId) async {
    try {
      // รับชื่อผู้ใช้ปัจจุบัน (ผู้เพิ่ม)
      final String inviterName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'A team member';

      // ส่งการแจ้งเตือนเชิญเข้าร่วมโปรเจค
      await _notificationService.sendProjectInvitation(
        userId: userId,
        projectId: widget.projectId,
        projectName: _projectName ?? 'Project',
        inviterName: inviterName,
      );

      // ส่งการแจ้งเตือนเกี่ยวกับการเพิ่มเข้าแผนก
      await _notificationService.createNotification(
        userId: userId,
        type: 'department_added',
        message:
            '$inviterName added you to ${_departmentName ?? 'a department'} in ${_projectName ?? 'a project'}',
        additionalData: {
          'projectId': widget.projectId,
          'projectName': _projectName,
          'departmentId': widget.departmentId,
          'departmentName': _departmentName,
          'inviterId': _currentUserId,
          'inviterName': inviterName,
        },
      );

      print('Notifications sent to added user successfully');
    } catch (e) {
      print('Error sending notifications to added user: $e');
      // ไม่ throw exception เพื่อไม่ให้กระทบกับการทำงานหลัก
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.secondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Email input field using AuthTextField styling
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'User Email',
                labelStyle: const TextStyle(color: AppColors.labelText),
                hintText: 'Enter email of user to add',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                prefixIcon: const Icon(Icons.email, color: AppColors.secondary),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 15.0,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: AppColors.secondary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                // Add button styled like AuthButton
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.buttonColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D8D8D), Color(0xFF5A5A5A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addPeople,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                            : const Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// Helper function to show the dialog
void showAddPeopleDialog(
  BuildContext context,
  String projectId,
  String departmentId,
) {
  showDialog(
    context: context,
    builder:
        (context) => AddPeopleDialog(
          title: 'ADD PEOPLE',
          projectId: projectId,
          departmentId: departmentId,
        ),
  ).then((result) {
    // Handle the result if needed
    if (result == true) {
      // User was added successfully
    }
  });
}
