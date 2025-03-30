import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:teammate/widgets/common/card/card_ongoingTask.dart';
import 'package:teammate/widgets/common/dialog/dialog_addAdmin.dart';
import 'package:teammate/widgets/common/card/card_departments.dart';

class WorkPageTwo extends StatefulWidget {
  final String title;
  final Map<String, dynamic> data;
  final FirestoreProjectService _projectService = FirestoreProjectService();

  WorkPageTwo({super.key, required this.title, required this.data});

  @override
  State<WorkPageTwo> createState() => _WorkPageTwoState();
}

class _WorkPageTwoState extends State<WorkPageTwo> {
  late Future<bool> _isUserHeadFuture;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _isUserHeadFuture = _checkIfUserIsHead();
  }

  Future<bool> _checkIfUserIsHead() async {
    if (userId == null || widget.data['projectId'] == null) return false;
    return await widget._projectService.isUserHeadOfProject(
      widget.data['projectId'],
      userId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          FutureBuilder<bool>(
            future: _isUserHeadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(); // รอโหลด ไม่ต้องแสดงอะไร
              }
              if (snapshot.hasError || !(snapshot.data ?? false)) {
                return const SizedBox(); // มี error หรือไม่ใช่หัวหน้าโครงการ → ซ่อนไอคอน
              }
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddAdminDialog(data: widget.data),
                  );
                },
                child: Image.asset('assets/images/plus_icon.png'),
              );
            },
          ),
          const SizedBox(width: 16.0),
          Image.asset('assets/images/noti.png'),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 0, 0),
        child: Column(
          children: [
            // Departments Section
            Row(
              children: [
                Container(
                  height: 50,
                  width: 8.5,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 160, 164, 168),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  'Departments',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CardDepartments(data: widget.data),
            const SizedBox(height: 20),

            // Ongoing Tasks Section
            Row(
              children: [
                Container(
                  height: 50,
                  width: 8.5,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 160, 164, 168),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  'Ongoing Tasks',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CardOngoingTasks(data: widget.data),
          ],
        ),
      ),
    );
  }
}
