import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/screens/creates/create_post.dart';
import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_document_service.dart'; // เพิ่ม service สำหรับเอกสาร
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
  final FirestoreDocumentService _documentService =
      FirestoreDocumentService(); // เพิ่ม service สำหรับเอกสาร

  String _headName = '';
  String _departmentName = '';
  String _projectName = '';
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> listShowWork = [];
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCombinedFeed();

    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 100 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCombinedFeed() async {
    try {
      setState(() {
        _isLoading = true;
      });

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

      // เพิ่มการโหลดเอกสาร
      _documentService.getDocumentsByDepartmentId(widget.departmentId).listen((
        documentsSnapshot,
      ) {
        _updateCombinedFeed(documentsSnapshot, 'document');
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
    // ลบรายการเก่าที่มี type เดียวกัน
    listShowWork.removeWhere((item) => item['type'] == type);

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      listShowWork.add({
        'id': doc.id,
        'type': type,
        'data': data,
        'createdAt': data['createdAt'] ?? Timestamp.now(),
      });
    }

    // เรียงลำดับตามเวลาล่าสุด
    listShowWork.sort((a, b) {
      final Timestamp aTime = a['createdAt'] as Timestamp;
      final Timestamp bTime = b['createdAt'] as Timestamp;
      return bTime.compareTo(aTime);
    });

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _isScrolled ? 100 : 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.white))
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: _isScrolled ? 20 : 25,
                      ),
                      child:
                          _isScrolled
                              ? // When scrolled - single line with ellipsis
                              Text(
                                '$_projectName : $_departmentName',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )
                              : // When not scrolled - can use more space
                              Text(
                                '$_projectName : $_departmentName',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                    ),
                    if (!_isScrolled) ...[
                      const Spacer(),
                      Text(
                        'Project Manager: $_headName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
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
        ).then((_) => _loadCombinedFeed());
      },
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: widget.color.withOpacity(0.1),
                child: Icon(Icons.edit, color: widget.color),
              ),
              const SizedBox(width: 16),
              Text(
                "Post something...",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
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
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => CreatePost(departmentId: widget.departmentId),
              ),
            ).then((_) => _loadCombinedFeed());
          },
          style: TextButton.styleFrom(foregroundColor: widget.color),
          child: const Text('Create the first post!'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildCreatePostBox(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ];
        },
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : listShowWork.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                  color: widget.color,
                  onRefresh: _loadCombinedFeed,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: listShowWork.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: FeedItemCard(
                          item: listShowWork[index],
                          themeColor: widget.color,
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
