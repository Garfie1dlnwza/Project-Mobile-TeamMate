import 'package:flutter/material.dart';

class ListWorkPage extends StatefulWidget {
  const ListWorkPage({super.key, required String departmentId, required String projectId});

  @override
  State<ListWorkPage> createState() => _ListWorkPageState();
}

class _ListWorkPageState extends State<ListWorkPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('test'));
  }
}
