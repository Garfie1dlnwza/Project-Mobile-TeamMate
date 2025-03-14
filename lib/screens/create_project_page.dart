import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/services/firestore_project_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/services/firestore_user_service.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({Key? key}) : super(key: key);

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirestoreProjectService _projectService = FirestoreProjectService();
  //final FirestoreUserService _userService = FirestoreUserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, bool> _selectedDepartments = {
    'Research & Development (R&D)': false,
    'Software Development / Engineering': false,
    'IT Operations / Infrastructure': false,
    'Cybersecurity / IT Security': false,
    'Quality Assurance (QA) / Testing': false,
    'Product Management': false,
    'Customer Support / IT Helpdesk': false,
    'Marketing & Sales': false,
    'Human Resources (HR)': false,
    'Finance & Accounting': false,
  };

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _getCurrentUserId() {
    // Get current user from Firebase Authentication
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        //เผื่อๆไว้
        const SnackBar(
          content: Text('You must be logged in to create a project'),
        ),
      );
      return null;
    }
    return currentUser.uid;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get current user ID
    String? currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      return; // Exit summit() if user is not logged in
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert selected departments to a list
      List<String> departments =
          _selectedDepartments.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();

      // Create project object
      Map<String, dynamic> projectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'headId': currentUserId,
        'admins': [], // Initially empty
        'departments': departments, //เป็น list ของ departments ที่่จะสร้าง
        'tasks': [], // Initially empty
        'polls': [], // Initially empty
        'documents': [], // Initially empty
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Call service to create project
      await _projectService.createProject(projectData);

      // if (mounted) {
      //   Navigator.pop(context);
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Project created successfully')),
      //   );
      // }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating project: $e')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Project',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  return TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a project name';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 36),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 50),
              Padding(
                padding: EdgeInsets.only(left: 15),
                child: const Text(
                  'Departments',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ..._selectedDepartments.keys.map((department) {
                return CheckboxListTile(
                  title: Text(department),
                  value: _selectedDepartments[department],
                  onChanged: (bool? value) {
                    setState(() {
                      _selectedDepartments[department] = value ?? false;
                    });
                  },
                );
              }).toList(),
              const SizedBox(height: 100),
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    height: 50,
                    width: 130,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 68, 68, 68),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Make edges sharp (square)
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                'Create',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
