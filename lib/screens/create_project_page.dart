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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreUserService userService = FirestoreUserService();

  // Define gray theme colors
  final Color _primaryGray = const Color(0xFF424242);
  final Color _lightGray = const Color(0xFF757575);
  final Color _darkGray = const Color(0xFF212121);
  final Color _accentGray = const Color(0xFF9E9E9E);
  final Color _backgroundGray = const Color(0xFFF5F5F5);

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

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    String? currentUserId = _auth.currentUser!.uid;
    if (currentUserId == null) {
      print('uid user is null');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> departments =
          _selectedDepartments.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();

      Map<String, dynamic> projectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'users':[currentUserId],
        'headId': currentUserId,
        'admins': [],
        'departments': departments,
        'tasks': [],
        'polls': [],
        'documents': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      String projectID = await _projectService.createProject(projectData);
      await userService.updateUserProjects(currentUserId, projectID);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: _darkGray,
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
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.light(
          primary: _primaryGray,
          secondary: _accentGray,
          surface: _backgroundGray,
          background: _backgroundGray,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _darkGray,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryGray, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _lightGray),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          labelStyle: TextStyle(color: _primaryGray),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkGray,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _primaryGray;
            }
            return null;
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
        ),
      ),
      child: Scaffold(
        backgroundColor: _backgroundGray,
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Project Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a project name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(
                    'Departments',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _darkGray,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children:
                          _selectedDepartments.keys.map((department) {
                            return CheckboxListTile(
                              title: Text(
                                department,
                                style: TextStyle(color: _darkGray),
                              ),
                              value: _selectedDepartments[department],
                              onChanged: (bool? value) {
                                setState(() {
                                  _selectedDepartments[department] =
                                      value ?? false;
                                });
                              },
                              activeColor: _primaryGray,
                              checkColor: Colors.white,
                            );
                          }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    height: 50,
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _darkGray.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Create',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle_outline),
                                ],
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
