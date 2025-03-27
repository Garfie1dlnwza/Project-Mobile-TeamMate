import 'package:flutter/material.dart';
import 'package:teammate/screens/creates/create_document_page.dart';
import 'package:teammate/screens/creates/create_poll_page.dart';
import 'package:teammate/screens/creates/create_task_page.dart';

class ListWorkPage extends StatefulWidget {
  final String departmentId;
  final String projectId;

  const ListWorkPage({
    super.key,
    required this.departmentId,
    required this.projectId,
  });

  @override
  State<ListWorkPage> createState() => _ListWorkPageState();
}

class _ListWorkPageState extends State<ListWorkPage> {
  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'CREATE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                ),

                ListTile(
                  minTileHeight: 60,
                  leading: Icon(Icons.work),
                  title: Text('Work'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CreateTaskPage(
                              projectId: widget.projectId,
                              departmentId: widget.departmentId,
                            ),
                      ),
                    );
                  },
                ),
                ListTile(
                  minTileHeight: 60,
                  leading: Icon(Icons.poll),
                  title: Text('Poll'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CreaetPollPage(
                              projectId: widget.projectId,
                              departmentId: widget.departmentId,
                            ),
                      ),
                    );
                  },
                ),
                ListTile(
                  minTileHeight: 60,
                  leading: Icon(Icons.document_scanner),
                  title: Text('Document'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CreateDocumentPage(
                              projectId: widget.projectId,
                              departmentId: widget.departmentId,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Text('test'),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16),
        child: FloatingActionButton(
          onPressed: _showCreateBottomSheet,
          backgroundColor: Colors.grey[800],
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
