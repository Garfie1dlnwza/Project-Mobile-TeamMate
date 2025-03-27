import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/screens/myworks/work_page.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:uuid/uuid.dart';
// Import the WorkPageThree


class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({Key? key}) : super(key: key);

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirestoreProjectService _projectService = FirestoreProjectService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreUserService userService = FirestoreUserService();
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Define minimal theme colors
  final Color _textColor = const Color(0xFF303030);
  final Color _primaryColor = const Color.fromARGB(255, 69, 69, 69);
  final Color _accentColor = const Color.fromARGB(255, 77, 77, 77);
  final Color _backgroundColor = Colors.white;
  final Color _cardColor = const Color(0xFFF5F5F5);

  final Map<String, bool> _selectedDepartments = {
    'R&D': false,
    'Software': false,
    'IT Ops': false,
    'Security': false,
    'QA': false,
    'Product': false,
    'Support': false,
    'Marketing': false,
    'HR': false,
    'Finance': false,
    'Design': false,
    'DataScience': false,
    'DevOps': false,
    'Legal': false,
    'Admin': false,
    'Executive': false,
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with simpler animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('uid user is null');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create initial project data
      Map<String, dynamic> projectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'headId': currentUserId,
        'departments': [], // Initialize with empty array
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Create the project and get its ID
      String projectID = await _projectService.createProject(projectData);

      // Create departments and collect their IDs
      List<String> departmentIds = [];
      Map<String, String> departmentNameToIdMap =
          {}; // Map to store department name -> ID

      for (var entry in _selectedDepartments.entries) {
        if (entry.value) {
          Map<String, dynamic> departmentData = {
            'name': entry.key,
            'admins': [],
            'users': [],
            'polls': [],
            'documents': [],
            'tasks': [],
            'questions': [],
            'projectId': projectID, // Store reference to project
          };

          String departmentId = await _departmentService.createDepartment(
            departmentData,
          );
          print("✅ Department created with ID: $departmentId");
          departmentIds.add(departmentId);
          departmentNameToIdMap[entry.key] = departmentId; // Store the mapping
        }
      }

      // Update project with department IDs
      if (departmentIds.isNotEmpty) {
        await _projectService.updateProject(projectID, {
          'departments': departmentIds,
        });
        print("✅ Project updated with departments: $departmentIds");
      }

      // Add project to user's projects
      await userService.updateUserProjects(currentUserId, projectID);
      print("✅ Project created with ID: $projectID");

      // Choose the first department to navigate to
      if (departmentIds.isNotEmpty) {
        String firstDepartmentId = departmentIds[0];
        String firstDepartmentName = "";

        // Find the name of the first department
        for (var entry in departmentNameToIdMap.entries) {
          if (entry.value == firstDepartmentId) {
            firstDepartmentName = entry.key;
            break;
          }
        }

        if (mounted) {
          // Navigate to WorkPageThree instead of just popping
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WorkPage(title: 'MY WORK',)),
          );
        }
      } else {
        // If no departments were created, just go back
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: _textColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDepartmentsGrid() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _selectedDepartments.length,
        itemBuilder: (context, index) {
          String department = _selectedDepartments.keys.elementAt(index);
          bool isSelected = _selectedDepartments[department] ?? false;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected ? _primaryColor : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDepartments[department] = !isSelected;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color:
                          isSelected
                              ? _primaryColor
                              : Colors.grey.withOpacity(0.5),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        department, // ใช้ชื่อย่อโดยตรง
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.light(
          primary: _primaryColor,
          secondary: _accentColor,
          surface: _backgroundColor,
          background: _backgroundColor,
          onPrimary: Colors.white,
          onSurface: _textColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _backgroundColor,
          foregroundColor: _textColor,
          elevation: 0,
          iconTheme: IconThemeData(color: _textColor),
          titleTextStyle: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _cardColor,
          hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.redAccent.withOpacity(0.5),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _primaryColor;
            }
            return null;
          }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        cardTheme: CardTheme(
          color: _cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: const Text('Create Project'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                children: [
                  // Project Name Section
                  _buildSectionTitle('Project Information'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Project Name'),
                    style: TextStyle(color: _textColor, fontSize: 16),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a project name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(hintText: 'Description'),
                    style: TextStyle(color: _textColor, fontSize: 16),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Departments Section
                  _buildSectionTitle('Departments'),
                  const SizedBox(height: 8),
                  Text(
                    'Select the departments that will be involved',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Department Cards
                  _buildDepartmentsGrid(),

                  const SizedBox(height: 24),

                  // Warning message if no departments selected
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _nameController,
                    builder: (context, nameValue, _) {
                      bool anyDepartmentSelected = _selectedDepartments.values
                          .any((selected) => selected);
                      return !anyDepartmentSelected
                          ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.amber[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Please select at least one department to navigate to work page after creation',
                                    style: TextStyle(
                                      color: Colors.amber[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: SizedBox(
                      width: double.infinity,
                      child: Center(
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Create Project',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
