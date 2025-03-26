import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teammate/screens/myworks/work_page3.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_project_service.dart';

class CardDepartments extends StatefulWidget {
  final Map<String, dynamic> data;
  const CardDepartments({super.key, required this.data});

  @override
  State<CardDepartments> createState() => _CardDepartmentsState();
}

class _CardDepartmentsState extends State<CardDepartments> {
  final FirestoreProjectService _projectService = FirestoreProjectService();
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();

  List<Color> projectColors = [
    Colors.teal.shade200,
    Colors.pink.shade200,
    Colors.purple.shade200,
    Colors.blueGrey.shade200,
  ];

  List<String> departmentsIds = [];

  @override
  void initState() {
    super.initState();

    try {
      if (widget.data.containsKey('departments') &&
          widget.data['departments'] != null &&
          widget.data['departments'] is List) {
        final deptsList = widget.data['departments'] as List<dynamic>;
        departmentsIds = deptsList.map((item) => item.toString()).toList();
        print('List DepartmentIds $departmentsIds');
      }
    } catch (e) {
      print('Error while parsing departments: $e');
    }
  }

  Widget _buildDepartmentCard(
    String projectId,
    String departmentId,
    String departmentName,
    Color color,
  ) {
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => WorkPageThree(
                    departmentId: departmentId,
                    departmentName: departmentName,
                    color: color,
                    projectId: projectId,
                  ),
            ),
          ),
      child: Container(
        height: 200,
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.group_work_rounded,
                    color: Colors.grey[800],
                    size: 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[800],
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              departmentName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.people, color: Colors.grey[800], size: 18),
                const SizedBox(width: 6),
                Text(
                  '12 Members',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
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
    return Card(
      shadowColor: Colors.transparent,
      color: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (String departmentId in departmentsIds)
              FutureBuilder<DocumentSnapshot>(
                future: _departmentService.getDepartmentById(departmentId),
                builder: (context, deptSnapshot) {
                  if (deptSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    );
                  } else if (deptSnapshot.hasError) {
                    return Text('Error: ${deptSnapshot.error}');
                  } else if (!deptSnapshot.hasData ||
                      !deptSnapshot.data!.exists) {
                    return const Text('Department not found');
                  } else {
                    var departmentData =
                        deptSnapshot.data!.data() as Map<String, dynamic>;
                    String departmentName =
                        departmentData['name'] ?? 'Unnamed Department';
                    String projectId = '';

                    // ค้นหา projectId จากเอกสาร department
                    if (departmentData.containsKey('projectId') &&
                        departmentData['projectId'] != null) {
                      projectId = departmentData['projectId'];
                      print('Found projectId in department: $projectId');
                    } else {
                      // ใช้ ID จาก widget.data ถ้ามี
                      projectId = widget.data['id'] ?? '';
                      print('Using fallback projectId: $projectId');
                    }

                    return _buildDepartmentCard(
                      projectId,
                      departmentId,
                      departmentName,
                      projectColors[departmentsIds.indexOf(departmentId) %
                          projectColors.length],
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
