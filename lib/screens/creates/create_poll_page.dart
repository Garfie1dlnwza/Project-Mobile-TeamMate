import 'package:flutter/material.dart';

class CreaetPollPage extends StatelessWidget {
  final String projectId;
  final String departmentId;

  const CreaetPollPage({
    super.key,
    required this.projectId,
    required this.departmentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Create Poll',
          style: const TextStyle(fontWeight: FontWeight.bold),)),
      body: Center(
        child: Text('Project ID: $projectId, Department ID: $departmentId'),
      ),
    );
  }
}