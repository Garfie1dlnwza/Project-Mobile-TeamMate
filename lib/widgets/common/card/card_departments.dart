import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teammate/screens/myworks/work_page3.dart';
import 'package:teammate/services/firestore_department_service.dart';

class CardDepartments extends StatefulWidget {
  final Map<String, dynamic> data;
  const CardDepartments({super.key, required this.data});

  @override
  State<CardDepartments> createState() => _CardDepartmentsState();
}

class _CardDepartmentsState extends State<CardDepartments> {
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();

  final List<Color> departmentColors = [
    Colors.teal.shade200,
    Colors.pink.shade200,
    Colors.purple.shade200,
    Colors.blueGrey.shade200,
    Colors.amber.shade200,
    Colors.indigo.shade200,
  ];

  List<String> departmentIds = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _extractDepartmentIds();
  }

  void _extractDepartmentIds() {
    try {
      setState(() => _isLoading = true);

      if (widget.data.containsKey('departments') &&
          widget.data['departments'] != null &&
          widget.data['departments'] is List) {
        final deptsList = widget.data['departments'] as List<dynamic>;
        departmentIds = deptsList.map((item) => item.toString()).toList();
      } else {
        _errorMessage = 'No departments found in project data';
      }
    } catch (e) {
      _errorMessage = 'Error extracting departments: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDepartmentCard(
    String projectId,
    String departmentId,
    String departmentName,
    Color color,
    int memberCount,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.people, color: Colors.grey[800], size: 18),
                const SizedBox(width: 6),
                Text(
                  memberCount == 1 ? '1 Member' : '$memberCount Members',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No departments found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (departmentIds.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: departmentIds.length,
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (context, index) {
          final String departmentId = departmentIds[index];
          final Color color = departmentColors[index % departmentColors.length];

          return FutureBuilder<DocumentSnapshot>(
            future: _departmentService.getDepartmentById(departmentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('Department not found')),
                );
              }

              final departmentData =
                  snapshot.data!.data() as Map<String, dynamic>?;

              if (departmentData == null) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('No department data')),
                );
              }

              final String departmentName =
                  departmentData['name'] ?? 'Unnamed Department';
              String projectId = '';

              // Find projectId from the department document
              if (departmentData.containsKey('projectId') &&
                  departmentData['projectId'] != null) {
                projectId = departmentData['projectId'];
              } else {
                // Use the ID from widget.data as fallback
                projectId = widget.data['id'] ?? '';
              }

              // Get member count
              final List<dynamic> users = departmentData['users'] ?? [];
              final int memberCount = users.length;

              return _buildDepartmentCard(
                projectId,
                departmentId,
                departmentName,
                color,
                memberCount,
              );
            },
          );
        },
      ),
    );
  }
}
