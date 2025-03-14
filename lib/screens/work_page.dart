import 'package:flutter/material.dart';
import 'package:teammate/screens/create_project_page.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/widgets/common/header_bar.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class WorkPage extends StatefulWidget {
  final String title;
  const WorkPage({super.key, required this.title});

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  final FirestoreProjectService _projectService = FirestoreProjectService();
  final FirestoreUserService _userService = FirestoreUserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headbar(title: widget.title),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _projectService
                .getProjectsStream(), // ต้องเปลี่ยนเป็น method เอาเฉพาะ project ที่เราอยู่
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No projects found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var project = snapshot.data!.docs[index];

              //data ของ project เป็น Map<String, dynamic>
              Map<String, dynamic> data =
                  project.data() as Map<String, dynamic>;

              // Define a color based on project index for visual distinction
              List<Color> projectColors = [
                Colors.teal.shade200,
                Colors.pink.shade200,
                Colors.purple.shade200,
                Colors.blueGrey.shade200,
              ];

              Color projectColor = projectColors[index % projectColors.length];

              return Card(
                color: projectColor,
                margin: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    // Navigate to project details page
                    // You can implement this navigation
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['name'] ?? 'Unnamed Project',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    // Show options menu
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Text(
                            //   'Project Manager: ${_userService.getUserName(data['headId'])}',
                            //   style: const TextStyle(color: Colors.white),
                            // ),
                            FutureBuilder<String>(
                              future: _userService.getUserName(
                                data['headId'],
                              ), // ดึงชื่อจาก Firestore
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                    'Loading...',
                                    style: TextStyle(color: Colors.white),
                                  ); // แสดง Loading ระหว่างดึงข้อมูล
                                }

                                if (userSnapshot.hasError) {
                                  return Text(
                                    'Error: ${userSnapshot.error}',
                                    style: const TextStyle(color: Colors.white),
                                  ); // แสดง error ถ้ามีปัญหา
                                }

                                if (!userSnapshot.hasData) {
                                  return const Text(
                                    'Project Manager: Unknown',
                                    style: TextStyle(color: Colors.white),
                                  ); // กรณีที่ไม่มีข้อมูล
                                }

                                return Text(
                                  'Project Manager: ${userSnapshot.data}',
                                  style: const TextStyle(color: Colors.white),
                                ); // แสดงชื่อหัวหน้าโปรเจค
                              },
                            ),
                          ],
                        ),
                      ),
                      if (data['tasks'] != null &&
                          (data['tasks'] as List).isNotEmpty)
                        Container(
                          color: Colors.white,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WORK: ${(data['tasks'] as List).join(', ')}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
