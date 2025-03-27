import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPeoplePage extends StatefulWidget {
  final String title;
  final String projectId;
  final String departmentId;

  const AddPeoplePage({
    super.key,
    required this.title,
    required this.projectId,
    required this.departmentId,
  });

  @override
  State<AddPeoplePage> createState() => _AddPeoplePageState();
}

class _AddPeoplePageState extends State<AddPeoplePage> {
  final TextEditingController _emailController = TextEditingController();
  final FirestoreUserService _userService = FirestoreUserService();
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();
  final FirestoreProjectService _projectService = FirestoreProjectService();

  String? _currentUserId;
  bool _isLoading = false;
  DocumentSnapshot? _departmentData;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadDepartmentData();
  }

  Future<void> _loadDepartmentData() async {
    try {
      _departmentData = await _departmentService.getDepartmentById(
        widget.departmentId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading department data: $e')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with this email')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not authorized to add people')),
        );
        return;
      }
      print('departmentData: ${_departmentData}');

      // Check if user is admin so : don't add to users
      List<dynamic> adminList = _departmentData?['admins'] ?? [];
      if (adminList.contains(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This user is already in admins')),
        );
        return;
      }

      // Check if user is already in the department
      List<dynamic> userList = _departmentData?['users'] ?? [];
      if (userList.contains(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This user is already in this department'),
          ),
        );
        return;
      }

      // Add user to department
      await _departmentService.addUserToDepartment(
        departmentId: widget.departmentId,
        userId: userId,
      );

      // Add the Project to User
      await _userService.addProjectToUser(widget.projectId, userId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User added successfully')));

      _emailController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding user: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'User Email',
                hintText: 'Enter email of user to add',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: _isLoading ? null : _addPeople,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                        'Add People',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
