import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teammate/screens/creates/create_project_page.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/widgets/common/card/card_project.dart';
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
  final User? user = FirebaseAuth.instance.currentUser;

  // Define project colors for visual distinction
  final List<Color> projectColors = [
    Colors.teal.shade200,
    Colors.pink.shade200,
    Colors.purple.shade200,
    Colors.blueGrey.shade200,
  ];

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: Headbar(title: widget.title),
        body: const Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: Headbar(title: widget.title),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userService.getUserById(user!.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          // Get user's project IDs
          List<String> userProjectIDs = List<String>.from(
            userSnapshot.data!['projectIds'] ?? [],
          );

          if (userProjectIDs.isEmpty) {
            return const Center(child: Text('No projects found'));
          }

          // Only fetch projects that belong to this user
          return StreamBuilder<QuerySnapshot>(
            stream: _projectService.getUserProjectsStream(userProjectIDs),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
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
                  Map<String, dynamic> data =
                      project.data() as Map<String, dynamic>;
                  Color projectColor =
                      projectColors[index % projectColors.length];

                  return ProjectCard(
                    data: data,
                    projectColor: projectColor,
                    userService: _userService,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
