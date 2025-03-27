import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/theme/app_text_styles.dart';

class AddAdminDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const AddAdminDialog({super.key, required this.data});

  @override
  State<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {
  final TextEditingController _emailController = TextEditingController();
  final FirestoreUserService _userService = FirestoreUserService();
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();

  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;
  String? _currentUserId;
  bool _isLoading = false;
  List<String> departmentsIds = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      if (widget.data.containsKey('departments') &&
          widget.data['departments'] != null &&
          widget.data['departments'] is List) {
        final deptsList = widget.data['departments'] as List<dynamic>;
        departmentsIds = deptsList.map((item) => item.toString()).toList();
      }

      List<Map<String, String>> fetchedDepartments = [];
      for (String departmentId in departmentsIds) {
        DocumentSnapshot deptSnapshot = await _departmentService
            .getDepartmentById(departmentId);
        fetchedDepartments.add({
          'id': deptSnapshot.id,
          'name': deptSnapshot['name'] as String,
        });
      }

      setState(() {
        _departments = fetchedDepartments;
      });
    } catch (e) {
      print('Error while fetching departments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching departments: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _addAdmin() async {
    if (_emailController.text.isEmpty || _selectedDepartmentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter email and select a department'),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _userService.getUserIdByEmail(_emailController.text);

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user found with this email'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      DocumentSnapshot departmentDoc = await _departmentService
          .getDepartmentById(_selectedDepartmentId!);
      Map<String, dynamic> departmentData =
          departmentDoc.data() as Map<String, dynamic>;

      if (widget.data['headId'] != _currentUserId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You are not authorized to add admins to this department',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      List<dynamic> adminsList = departmentData['admins'] ?? [];
      if (adminsList.contains(userId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This user is already an admin of this department'),
              backgroundColor: Colors.amber,
            ),
          );
        }
        return;
      }

      await _departmentService.addAdminToDepartment(
        departmentId: _selectedDepartmentId!,
        adminId: userId,
      );

      await _userService.addProjectToUser(departmentData['projectId'], userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin added to ${departmentData['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _emailController.clear();
      setState(() {
        _selectedDepartmentId = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding admin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 10.0,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D8D8D), Color(0xFF5A5A5A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Add Admin',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: 24,
                    color: const Color(0xFF5A5A5A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'User Email',
                  labelStyle: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: 'Enter email of user to add as admin',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppColors.buttonColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedDepartmentId,
                hint: Text(
                  'Select Department',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                icon: Icon(
                  Icons.arrow_drop_down_circle,
                  color: AppColors.buttonColor,
                ),
                isExpanded: true,
                dropdownColor: Colors.white,
                items:
                    _departments
                        .map(
                          (dept) => DropdownMenuItem<String>(
                            value: dept['id'] as String,
                            child: Text(
                              dept['name'] as String,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartmentId = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(
                    Icons.business,
                    color: AppColors.buttonColor,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 14.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // ใช้ AuthButton แบบเดียวกับที่คุณให้มา
                Container(
                  width: 150,
                  height: 50,
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
                    onPressed: _isLoading ? null : _addAdmin,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
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
                            : Text(
                              'Add Admin',
                              style: AppTextStyles.buttonText,
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
