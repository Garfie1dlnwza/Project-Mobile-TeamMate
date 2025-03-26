import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_user_service.dart';

class AddAdminPage extends StatefulWidget {
  final String title;
  final Map<String, dynamic> data;
  const AddAdminPage({super.key, required this.title, required this.data});

  @override
  State<AddAdminPage> createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirestoreUserService _userService = FirestoreUserService();
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();

  // Variable to store departments
  List<Map<String, dynamic>> _departments = [];

  // Variable for selected department and current user ID
  String? _selectedDepartmentId;
  String? _currentUserId;

  // Loading state flag
  bool _isLoading = false;

  // List to store department IDs from the passed data
  List<String> departmentsIds = [];

  @override
  void initState() {
    super.initState();

    // Get the current user ID from passed data
    _currentUserId = widget.data['uid'];

    // Fetch the departments associated with the current user
    _fetchDepartments();
  }

  /// Fetch the departments associated with the current user
  Future<void> _fetchDepartments() async {
    try {
      // Check if departments are present in the passed data
      if (widget.data.containsKey('departments') &&
          widget.data['departments'] != null &&
          widget.data['departments'] is List) {
        final deptsList = widget.data['departments'] as List<dynamic>;
        departmentsIds = deptsList.map((item) => item.toString()).toList();
        print('List DepartmentIds $departmentsIds');
      }

      // Fetch departments by their IDs and store in a list
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching departments: $e')));
    }
  }

  /// Method to add admin to a department
  Future<void> _addAdmin() async {
    // Check if email and department are selected
    if (_emailController.text.isEmpty || _selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and select a department'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID by email from the Firestore service
      final userId = await _userService.getUserIdByEmail(_emailController.text);

      // Check if user ID exists
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with this email')),
        );
        return;
      }

      // Fetch the department document to check head ID
      DocumentSnapshot departmentDoc = await _departmentService
          .getDepartmentById(_selectedDepartmentId!);
      Map<String, dynamic> departmentData =
          departmentDoc.data() as Map<String, dynamic>;

      // Check if the current user is authorized to add admins to the department
      if (departmentData['headId'] != _currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You are not authorized to add admins to this department',
            ),
          ),
        );
        return;
      }

      // Add the user as admin to the department
      await _departmentService.addAdminToDepartment(
        departmentId: _selectedDepartmentId!,
        adminId: userId,
      );

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin added to ${departmentData['name']}')),
      );

      // Clear input fields and reset state
      _emailController.clear();
      setState(() {
        _selectedDepartmentId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding admin: $e')));
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Email input field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'User Email',
                hintText: 'Enter email of user to add as admin',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 36),

            // Dropdown to select department
            DropdownButtonFormField<String>(
              value: _selectedDepartmentId,
              hint: const Text('Select Department'),
              items:
                  _departments
                      .map(
                        (dept) => DropdownMenuItem<String>(
                          value: dept['id'] as String,
                          child: Text(dept['name'] as String),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartmentId = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 100),

            // Button to add admin
            ElevatedButton(
              onPressed: _isLoading ? null : _addAdmin,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                        'Add Admin',
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
