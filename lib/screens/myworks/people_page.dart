import 'package:flutter/material.dart';
import 'package:teammate/screens/myworks/add_admin_page.dart';
import 'package:teammate/screens/myworks/add_people_page.dart';

class PeoplePage extends StatefulWidget {
  final String projectId;
  final String departmentId;
  const PeoplePage({super.key, required this.projectId, required this.departmentId});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Text('test'),
      floatingActionButton: Padding(
        padding: EdgeInsets.all(16),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPeoplePage(
          title: 'ADD PEOPLE',
          projectId: widget.projectId,
          departmentId: widget.departmentId,
        ),
      ),
    );
          },
          backgroundColor: Colors.grey[800],
          shape: CircleBorder(),
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
