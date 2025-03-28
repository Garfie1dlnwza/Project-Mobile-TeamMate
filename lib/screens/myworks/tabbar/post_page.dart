import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/screens/creates/create_post.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_poll_service.dart';
import 'package:teammate/services/firestore_post.dart';
import 'package:teammate/services/firestore_project_service.dart';
import 'package:teammate/services/firestore_task_service.dart';
import 'package:teammate/widgets/common/card/card_feedItem.dart';

class PostPage extends StatefulWidget {
  final String departmentId;
  final String projectId;
  final Color color;

  const PostPage({
    super.key,
    required this.departmentId,
    required this.projectId,
    required this.color,
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage>
    with SingleTickerProviderStateMixin {
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();
  final FirestoreProjectService _projectService = FirestoreProjectService();
  final FirestorePollService _pollService = FirestorePollService();
  final FirestoreTaskService _taskService = FirestoreTaskService();
  final FirestorePostService _postService = FirestorePostService();

  String _headName = '';
  String _departmentName = '';
  String _projectName = '';
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> listShowWork = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCombinedFeed();
  }

  Future<void> _loadCombinedFeed() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Set up listeners for each content type
      _taskService.getTaskbyDepartmentID(widget.departmentId).listen((
        tasksSnapshot,
      ) {
        _updateCombinedFeed(tasksSnapshot, 'task');
      });

      _postService.getPostsForDepartmentId(widget.departmentId).listen((
        postsSnapshot,
      ) {
        _updateCombinedFeed(postsSnapshot, 'post');
      });

      _pollService.getPollbyDepartmentID(widget.departmentId).listen((
        pollsSnapshot,
      ) {
        _updateCombinedFeed(pollsSnapshot, 'poll');
      });
    } catch (e) {
      debugPrint('Error setting up feed listeners: $e');
      setState(() {
        _errorMessage = 'Failed to load feed';
        _isLoading = false;
      });
    }
  }

  void _updateCombinedFeed(QuerySnapshot snapshot, String type) {
    // Remove existing items of this type
    listShowWork.removeWhere((item) => item['type'] == type);

    // Add new items with type information
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      listShowWork.add({
        'id': doc.id,
        'type': type,
        'data': data,
        'createdAt': data['createdAt'] ?? Timestamp.now(),
      });
    }

    // Sort by createdAt (newest first)
    listShowWork.sort((a, b) {
      final Timestamp aTime = a['createdAt'] as Timestamp;
      final Timestamp bTime = b['createdAt'] as Timestamp;
      return bTime.compareTo(aTime);
    });

    // Update the UI
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _loadDepartmentName(),
        _loadProjectName(),
        _loadHeadName(),
      ]);

      setState(() {
        _departmentName = results[0]!;
        _projectName = results[1]!;
        _headName = results[2] ?? 'No head assigned';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data';
        _isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  Future<String> _loadDepartmentName() async {
    try {
      final doc = await _departmentService.getDepartmentById(
        widget.departmentId,
      );
      if (doc.exists) {
        return doc.get('name') ?? 'Unnamed Department';
      }
      return 'Department not found';
    } catch (e) {
      debugPrint('Error loading department name: $e');
      return 'Error loading department';
    }
  }

  Future<String> _loadProjectName() async {
    try {
      final doc = await _projectService.getProjectById(widget.projectId);
      if (doc.exists) {
        return doc.get('name') ?? 'Unnamed Project';
      }
      return 'Project not found';
    } catch (e) {
      debugPrint('Error loading project name: $e');
      return 'Error loading project';
    }
  }

  Future<String?> _loadHeadName() async {
    try {
      return await _projectService.getHeadNameByHeadId(widget.projectId);
    } catch (e) {
      debugPrint('Error loading head name: $e');
      return 'Error loading head';
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 18, 18, 18).withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.white))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_projectName : $_departmentName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 65),
                  Text(
                    'Project Manager: $_headName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostBox() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreatePost(departmentId: widget.departmentId),
          ),
        ).then((_) {
          // Refresh the feed when returning from create post
          _loadCombinedFeed();
        });
      },
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/default.png',
                opacity: const AlwaysStoppedAnimation(0.5),
              ),
              const SizedBox(width: 30),
              Text(
                "Post something...",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No content yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post something!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildCreatePostBox(),
            const SizedBox(height: 20),

            // Feed content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : listShowWork.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                        onRefresh: () async {
                          // Refresh the feed
                          await _loadCombinedFeed();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: listShowWork.length,
                          itemBuilder: (context, index) {
                            return FeedItemCard(
                              item: listShowWork[index],
                              themeColor: widget.color,
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
