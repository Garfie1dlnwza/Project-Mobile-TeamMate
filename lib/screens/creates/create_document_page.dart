import 'package:flutter/material.dart';

class CreateDocumentPage extends StatelessWidget {
  final String projectId;
  final String departmentId;

  const CreateDocumentPage({
    super.key,
    required this.projectId,
    required this.departmentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Create Document',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text('Project ID: $projectId, Department ID: $departmentId'),
      ),
    );
  }
}
