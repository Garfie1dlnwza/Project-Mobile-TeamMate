import 'package:flutter/material.dart';
import 'package:teammate/screens/creates/create_post.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_project_service.dart';

class PostPage extends StatefulWidget {
  final String departmentId;
  final String projectId;
  final Color color;

  const PostPage({
    super.key,
    required this.departmentId,
    required this.projectId,
    required this.color,
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage>
    with SingleTickerProviderStateMixin {
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();
  final FirestoreProjectService _projectService = FirestoreProjectService();
  String _headName = '';
  String _departmentName = '';
  String _projectName = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _loadDepartmentName(),
        _loadProjectName(),
        _loadHeadName(),
      ]);

      setState(() {
        _departmentName = results[0]!;
        _projectName = results[1]!;
        _headName = results[2] ?? 'No head assigned';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data';
        _isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  Future<String> _loadDepartmentName() async {
    try {
      final doc = await _departmentService.getDepartmentById(
        widget.departmentId,
      );
      if (doc.exists) {
        return doc.get('name') ?? 'Unnamed Department';
      }
      return 'Department not found';
    } catch (e) {
      debugPrint('Error loading department name: $e');
      return 'Error loading department';
    }
  }

  Future<String> _loadProjectName() async {
    try {
      final doc = await _projectService.getProjectById(widget.projectId);
      if (doc.exists) {
        return doc.get('name') ?? 'Unnamed Project';
      }
      return 'Project not found';
    } catch (e) {
      debugPrint('Error loading project name: $e');
      return 'Error loading project';
    }
  }

  Future<String?> _loadHeadName() async {
    try {
      return await _projectService.getHeadNameByHeadId(widget.projectId);
    } catch (e) {
      debugPrint('Error loading head name: $e');
      return 'Error loading head';
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 18, 18, 18).withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),

            /// changes position of shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.white))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_projectName : $_departmentName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 65),
                  Text(
                    'Project Manager: $_headName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            CreatePost(departmentId: widget.departmentId),
                  ),
                );
              },
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color.fromARGB(255, 255, 255, 255),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        0,
                        0,
                        0,
                      ).withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,

                    children: [
                      Image.asset(
                        'assets/images/default.png',
                        opacity: AlwaysStoppedAnimation(0.5),
                      ),
                      const SizedBox(width: 30),
                      Text(
                        "Post something...",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
