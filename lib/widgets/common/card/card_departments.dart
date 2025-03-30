import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teammate/screens/myworks/work_page3.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_project_service.dart';

class CardDepartments extends StatefulWidget {
  final Map<String, dynamic> data;
  const CardDepartments({super.key, required this.data});

  @override
  State<CardDepartments> createState() => _CardDepartmentsState();
}

class _CardDepartmentsState extends State<CardDepartments> {
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();
  final FirestoreProjectService _projectService = FirestoreProjectService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Modern accent colors for departments
  final List<Color> accentColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFEC4899), // Pink
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF8B5CF6), // Purple
  ];

  List<String> departmentIds = [];
  List<String> userDepartmentIds =
      []; // Departments the current user belongs to
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProjectHead = false;

  @override
  void initState() {
    super.initState();
    _loadDepartmentsData();
  }

  Future<void> _loadDepartmentsData() async {
    try {
      setState(() => _isLoading = true);

      // Get current user ID
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Extract all department IDs from project data
      if (widget.data.containsKey('departments') &&
          widget.data['departments'] != null &&
          widget.data['departments'] is List) {
        final deptsList = widget.data['departments'] as List<dynamic>;
        departmentIds = deptsList.map((item) => item.toString()).toList();
      } else {
        setState(() {
          _errorMessage = 'No departments found in project data';
          _isLoading = false;
        });
        return;
      }

      // Get project ID
      final String projectId =
          widget.data['projectId'] ?? widget.data['id'] ?? '';

      // Check if user is project head
      if (projectId.isNotEmpty) {
        _isProjectHead = await _projectService.isUserHeadOfProject(
          projectId,
          currentUser.uid,
        );
      }

      // If user is not project head, get departments they have access to
      if (!_isProjectHead) {
        // Get all departments where the user is a member or admin
        userDepartmentIds = await _departmentService.getDepartmentIdsByUid(
          currentUser.uid,
        );
      }
    } catch (e) {
      _errorMessage = 'Error loading departments: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDepartmentCard(
    String projectId,
    String departmentId,
    String departmentName,
    Color accentColor,
    int memberCount,
    bool isUserAdmin,
    bool hasAccess,
  ) {
    // Project head always has access
    final bool effectiveHasAccess = _isProjectHead || hasAccess;

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: effectiveHasAccess ? Colors.grey[100] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              effectiveHasAccess
                  ? const Color.fromARGB(255, 40, 40, 40).withOpacity(0.15)
                  : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              effectiveHasAccess
                  ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => WorkPageThree(
                            departmentId: departmentId,
                            departmentName: departmentName,
                            color: accentColor,
                            projectId: projectId,
                          ),
                    ),
                  )
                  : () => _showNoAccessDialog(departmentName),
          child: Stack(
            children: [
              // Status badges
              if (isUserAdmin)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Show Project Head badge if user is project head and not admin of this dept
              if (_isProjectHead && !isUserAdmin && !hasAccess)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Head Access',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              if (!effectiveHasAccess)
                Positioned(
                  top: 0,
                  right: isUserAdmin ? null : 0,
                  left: isUserAdmin ? 0 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.only(
                        topRight:
                            isUserAdmin
                                ? Radius.zero
                                : const Radius.circular(16),
                        bottomLeft:
                            isUserAdmin
                                ? const Radius.circular(8)
                                : Radius.zero,
                        topLeft:
                            isUserAdmin
                                ? const Radius.circular(16)
                                : Radius.zero,
                        bottomRight:
                            isUserAdmin
                                ? Radius.zero
                                : const Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'No Access',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Card content with optional lock overlay
              Stack(
                children: [
                  // Basic content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with icon and arrow
                        Row(
                          children: [
                            // Department icon with accent color
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(
                                  effectiveHasAccess ? 0.1 : 0.05,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.business_outlined,
                                color:
                                    effectiveHasAccess
                                        ? accentColor
                                        : Colors.grey[400],
                                size: 20,
                              ),
                            ),

                            const Spacer(),

                            // Arrow or lock indicator
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                effectiveHasAccess
                                    ? Icons.arrow_forward_ios_rounded
                                    : Icons.lock_outline,
                                color: Colors.grey[500],
                                size: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Department name
                        Text(
                          departmentName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color:
                                effectiveHasAccess
                                    ? Colors.grey[850]
                                    : Colors.grey[600],
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // Department ID
                        Text(
                          'ID: ${departmentId.substring(0, Math.min(8, departmentId.length))}${departmentId.length > 8 ? '...' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),

                        const Spacer(),

                        // Divider
                        Divider(color: Colors.grey.withOpacity(0.15)),

                        const SizedBox(height: 12),

                        // Member count
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(
                                  effectiveHasAccess ? 0.1 : 0.05,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.people_outline,
                                color:
                                    effectiveHasAccess
                                        ? accentColor
                                        : Colors.grey[400],
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              memberCount == 1
                                  ? '1 Member'
                                  : '$memberCount Members',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color:
                                    effectiveHasAccess
                                        ? Colors.grey[700]
                                        : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Optional semi-transparent overlay for no-access departments
                  if (!effectiveHasAccess)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ColorFilter.mode(
                            Colors.white.withOpacity(0.1),
                            BlendMode.saturation,
                          ),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoAccessDialog(String departmentName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.grey),
                SizedBox(width: 10),
                Text('Access Restricted'),
              ],
            ),
            content: Text(
              'You don\'t have access to the "$departmentName" department. Please contact your project manager or department admin to request access.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildLoadingCard(int index) {
    final Color accentColor = accentColors[index % accentColors.length];

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.red.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 32),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
      ),
      margin: const EdgeInsets.only(right: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 42, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No departments available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3, // Show 3 loading indicators
          padding: const EdgeInsets.only(right: 16),
          itemBuilder: (context, index) {
            return _buildLoadingCard(index);
          },
        ),
      );
    }

    if (departmentIds.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: departmentIds.length,
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (context, index) {
          final String departmentId = departmentIds[index];
          final Color accentColor = accentColors[index % accentColors.length];
          final String? currentUserId = _auth.currentUser?.uid;

          return FutureBuilder<DocumentSnapshot>(
            future: _departmentService.getDepartmentById(departmentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingCard(index);
              }

              if (snapshot.hasError) {
                return _buildErrorCard('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return _buildErrorCard('Department not found');
              }

              final departmentData =
                  snapshot.data!.data() as Map<String, dynamic>?;

              if (departmentData == null) {
                return _buildErrorCard('No department data');
              }

              final String departmentName =
                  departmentData['departmentName'] ??
                  departmentData['name'] ??
                  'Unnamed Department';
              String projectId = '';

              // Find projectId from the department document
              if (departmentData.containsKey('projectId') &&
                  departmentData['projectId'] != null) {
                projectId = departmentData['projectId'];
              } else {
                // Use the ID from widget.data as fallback
                projectId = widget.data['id'] ?? '';
              }

              // Get member count
              final List<dynamic> users = departmentData['users'] ?? [];
              final List<dynamic> admins = departmentData['admins'] ?? [];

              // Count total members (users + admins) without duplicates
              final Set<dynamic> uniqueMembers = {...users, ...admins};
              final int memberCount = uniqueMembers.length;

              // Check if current user is an admin of this department
              final bool isUserAdmin = admins.contains(currentUserId);

              // Check if current user has access to this department (directly, not as project head)
              final bool hasAccess =
                  users.contains(currentUserId) ||
                  admins.contains(currentUserId);

              return _buildDepartmentCard(
                projectId,
                departmentId,
                departmentName,
                accentColor,
                memberCount,
                isUserAdmin,
                hasAccess,
              );
            },
          );
        },
      ),
    );
  }
}

// Simple Math utility to avoid importing dart:math for just one function
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
