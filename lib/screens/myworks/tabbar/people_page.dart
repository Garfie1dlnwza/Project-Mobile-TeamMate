import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/widgets/common/dialog/dialog_addPeople.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_user_service.dart';

class PeoplePage extends StatefulWidget {
  final String projectId;
  final String departmentId;

  const PeoplePage({
    super.key,
    required this.projectId,
    required this.departmentId,
  });

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();
  final FirestoreUserService _userService = FirestoreUserService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    if (_currentUserId != null) {
      final isAdmin = await _departmentService.isUserAdminOfDepartment(
        widget.departmentId,
        _currentUserId!,
      );

      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showUserOptions(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Make Admin'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _departmentService.addAdminToDepartment(
                      departmentId: widget.departmentId,
                      adminId: userId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$userName is now an admin')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text(
                  'Remove from Department',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Remove User'),
                          content: Text(
                            'Are you sure you want to remove $userName from this department?',
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: const Text(
                                'Remove',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                try {
                                  // Remove user logic here
                                  // This would require a new method in the department service
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$userName has been removed',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _departmentService
                .getDepartmentById(widget.departmentId)
                .asStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Department not found'));
          }

          final departmentData = snapshot.data!.data() as Map<String, dynamic>?;

          if (departmentData == null) {
            return const Center(child: Text('No department data available'));
          }

          final List<dynamic> adminIds = departmentData['admins'] ?? [];
          final List<dynamic> userIds = departmentData['users'] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (adminIds.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Administrators',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildUserList(adminIds, true),
                const Divider(),
              ],
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Members',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildUserList(userIds, false),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16),
        child: FloatingActionButton(
          onPressed: () {
            // Use the dialog instead of navigating to a new page
            showDialog(
              context: context,
              builder:
                  (context) => AddPeopleDialog(
                    title: 'ADD PEOPLE',
                    projectId: widget.projectId,
                    departmentId: widget.departmentId,
                  ),
            ).then((result) {
              // Optionally refresh the page if a user was added successfully
              if (result == true) {
                setState(() {
                  // This will trigger a rebuild, which will refresh the StreamBuilder
                });
              }
            });
          },
          backgroundColor: Colors.grey[800],
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUserList(List<dynamic> userIds, bool isAdminList) {
    return Expanded(
      child: ListView.builder(
        itemCount: userIds.length,
        itemBuilder: (context, index) {
          final userId = userIds[index];

          return FutureBuilder<DocumentSnapshot>(
            future: _userService.getUserById(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Loading...'),
                );
              }

              if (snapshot.hasError) {
                return ListTile(
                  leading: const Icon(Icons.error),
                  title: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('User not found'),
                );
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;

              if (userData == null) {
                return const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('No user data'),
                );
              }

              final String userName = userData['name'] ?? 'No name';
              final String userEmail = userData['email'] ?? 'No email';

              return ListTile(
                leading: CircleAvatar(child: Text(userName[0].toUpperCase())),
                title: Text(userName),
                subtitle: Text(userEmail),
                trailing:
                    _isAdmin && !isAdminList
                        ? IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showUserOptions(userId, userName);
                          },
                        )
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}
