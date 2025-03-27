import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/widgets/common/dialog/dialog_addPeople.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/widgets/common/seach_member.dart';
import 'package:teammate/widgets/common/tab_admin.dart';
import 'package:teammate/widgets/common/tab_member.dart';

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

class _PeoplePageState extends State<PeoplePage> with TickerProviderStateMixin {
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();
  final FirestoreUserService _userService = FirestoreUserService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  bool _isAdmin = false;
  bool _isLoading = true;
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Search bar
              PeopleSearchBar(
                controller: _searchController,
                searchQuery: _searchQuery,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryGradientEnd,
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.transparent,
                indicatorWeight: 3,
                tabs: const [Tab(text: 'ALL MEMBERS'), Tab(text: 'ADMINS')],
              ),
            ],
          ),
        ),
      ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Department not found',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final departmentData = snapshot.data!.data() as Map<String, dynamic>?;

          if (departmentData == null) {
            return const Center(
              child: Text(
                'No department data available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final List<dynamic> adminIds = departmentData['admins'] ?? [];
          final List<dynamic> userIds = departmentData['users'] ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              // All members tab
              AllMembersTab(
                userIds: userIds,
                adminIds: adminIds,
                isAdmin: _isAdmin,
                searchQuery: _searchQuery,
                userService: _userService,
                departmentService: _departmentService,
                departmentId: widget.departmentId,
                projectId: widget.projectId,
              ),
              // Admins tab
              AdminsTab(
                adminIds: adminIds,
                searchQuery: _searchQuery,
                userService: _userService,
                isAdmin: _isAdmin,
                departmentService: _departmentService,
                departmentId: widget.departmentId,
                projectId: widget.projectId,
              ),
            ],
          );
        },
      ),
      floatingActionButton:
          _isAdmin
              ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AddPeopleDialog(
                          title: 'ADD PEOPLE',
                          projectId: widget.projectId,
                          departmentId: widget.departmentId,
                        ),
                  ).then((result) {
                    if (result == true) {
                      setState(() {});
                    }
                  });
                },
                backgroundColor: Theme.of(context).primaryColor,
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text(
                  'ADD PEOPLE',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : null,
    );
  }
}
