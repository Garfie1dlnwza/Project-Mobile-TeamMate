import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/services/firestore_user_service.dart';

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color projectColor;
  final FirestoreUserService userService;

  const ProjectCard({
    super.key,
    required this.data,
    required this.projectColor,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: projectColor,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          // Navigate to project details page
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
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {
                          // Show options menu
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String?>(
                    future: userService.findNameById(data['headId']),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      if (userSnapshot.hasError) {
                        return Text(
                          'Error: ${userSnapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        );
                      }

                      if (!userSnapshot.hasData) {
                        return const Text(
                          'Project Manager: Unknown',
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      return Text(
                        'Project Manager: ${userSnapshot.data}',
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (data['tasks'] != null && (data['tasks'] as List).isNotEmpty)
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
  }
}
