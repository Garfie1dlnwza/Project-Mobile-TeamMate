import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/screens/creates/create_document_page.dart';
import 'package:teammate/screens/creates/create_poll_page.dart';
import 'package:teammate/screens/creates/create_task_page.dart';
import 'package:teammate/services/firestore_poll_service.dart';
import 'package:teammate/services/firestore_post.dart';
import 'package:teammate/services/firestore_task_service.dart';
import 'package:teammate/widgets/common/card/card_feedItem.dart';

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

enum WorkType { all, task, poll, post }

class _ListWorkPageState extends State<ListWorkPage> {
  final Color themeColor = Colors.grey[800]!;
  bool _isLoading = true;
  String? _errorMessage;
  WorkType _selectedType = WorkType.all;

  // Lists for each type of work
  List<Map<String, dynamic>> _taskList = [];
  List<Map<String, dynamic>> _pollList = [];
  List<Map<String, dynamic>> _postList = [];

  // Services
  final FirestorePollService _pollService = FirestorePollService();
  final FirestoreTaskService _taskService = FirestoreTaskService();
  final FirestorePostService _postService = FirestorePostService();

  @override
  void initState() {
    super.initState();
    _loadCombinedFeed();
  }

  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'CREATE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                ),
                ListTile(
                  minVerticalPadding: 16,
                  leading: const Icon(Icons.task),
                  title: const Text('Task'),
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
                    ).then((_) => _loadCombinedFeed());
                  },
                ),
                ListTile(
                  minVerticalPadding: 16,
                  leading: const Icon(Icons.poll),
                  title: const Text('Poll'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CreatePollPage(
                              projectId: widget.projectId,
                              departmentId: widget.departmentId,
                            ),
                      ),
                    ).then((_) => _loadCombinedFeed());
                  },
                ),
                ListTile(
                  minVerticalPadding: 16,
                  leading: const Icon(Icons.post_add),
                  title: const Text('Post'),
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
                    ).then((_) => _loadCombinedFeed());
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _loadCombinedFeed() async {
    try {
      setState(() {
        _isLoading = true;
        _taskList = [];
        _pollList = [];
        _postList = [];
      });

      // Load tasks
      _taskService.getTaskbyDepartmentID(widget.departmentId).listen((
        tasksSnapshot,
      ) {
        _updateTaskList(tasksSnapshot);
      });

      // Load posts
      _postService.getPostsForDepartmentId(widget.departmentId).listen((
        postsSnapshot,
      ) {
        _updatePostList(postsSnapshot);
      });

      // Load polls
      _pollService.getPollbyDepartmentID(widget.departmentId).listen((
        pollsSnapshot,
      ) {
        _updatePollList(pollsSnapshot);
      });
    } catch (e) {
      debugPrint('Error setting up feed listeners: $e');
      setState(() {
        _errorMessage = 'Failed to load content';
        _isLoading = false;
      });
    }
  }

  void _updateTaskList(QuerySnapshot snapshot) {
    _taskList = [];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      _taskList.add({
        'id': doc.id,
        'type': 'task',
        'data': data,
        'createdAt': data['createdAt'] ?? Timestamp.now(),
      });
    }

    _taskList.sort((a, b) {
      final Timestamp aTime = a['createdAt'] as Timestamp;
      final Timestamp bTime = b['createdAt'] as Timestamp;
      return bTime.compareTo(aTime);
    });

    setState(() {
      _isLoading = false;
    });
  }

  void _updatePollList(QuerySnapshot snapshot) {
    _pollList = [];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      _pollList.add({
        'id': doc.id,
        'type': 'poll',
        'data': data,
        'createdAt': data['createdAt'] ?? Timestamp.now(),
      });
    }

    _pollList.sort((a, b) {
      final Timestamp aTime = a['createdAt'] as Timestamp;
      final Timestamp bTime = b['createdAt'] as Timestamp;
      return bTime.compareTo(aTime);
    });

    setState(() {
      _isLoading = false;
    });
  }

  void _updatePostList(QuerySnapshot snapshot) {
    _postList = [];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      _postList.add({
        'id': doc.id,
        'type': 'post',
        'data': data,
        'createdAt': data['createdAt'] ?? Timestamp.now(),
      });
    }

    _postList.sort((a, b) {
      final Timestamp aTime = a['createdAt'] as Timestamp;
      final Timestamp bTime = b['createdAt'] as Timestamp;
      return bTime.compareTo(aTime);
    });

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 4),
          _buildFilterChip(WorkType.all, 'All', Icons.view_list),
          const SizedBox(width: 8),
          _buildFilterChip(WorkType.task, 'Tasks', Icons.task),
          const SizedBox(width: 8),
          _buildFilterChip(WorkType.poll, 'Polls', Icons.poll),
          const SizedBox(width: 8),
          _buildFilterChip(WorkType.post, 'Posts', Icons.post_add),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WorkType type, String label, IconData icon) {
    final bool isSelected = _selectedType == type;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      backgroundColor: Colors.grey[200],
      selectedColor: themeColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onSelected: (selected) {
        setState(() {
          _selectedType = type;
        });
      },
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Row(
        children: [
          Icon(icon, color: themeColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCategoryMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No work items in this project yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Press the + button to create new work items',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateBottomSheet,
            icon: const Icon(Icons.add),
            label: const Text('Create New'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredContent() {
    Widget content;

    switch (_selectedType) {
      case WorkType.all:
        final bool hasNoItems =
            _taskList.isEmpty && _pollList.isEmpty && _postList.isEmpty;

        if (hasNoItems) {
          content = _buildEmptyCategoryMessage(
            'No items available in this project',
          );
        } else {
          content = ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Tasks Section (if not filtered out)
              if (_taskList.isNotEmpty) ...[
                _buildCategoryHeader('Tasks', Icons.task),
                ...List.generate(_taskList.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FeedItemCard(
                      item: _taskList[index],
                      themeColor: themeColor,
                    ),
                  );
                }),
              ],

              // Polls Section (if not filtered out)
              if (_pollList.isNotEmpty) ...[
                _buildCategoryHeader('Polls', Icons.poll),
                ...List.generate(_pollList.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FeedItemCard(
                      item: _pollList[index],
                      themeColor: themeColor,
                    ),
                  );
                }),
              ],

              // Posts Section (if not filtered out)
              if (_postList.isNotEmpty) ...[
                _buildCategoryHeader('Posts', Icons.post_add),
                ...List.generate(_postList.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FeedItemCard(
                      item: _postList[index],
                      themeColor: themeColor,
                    ),
                  );
                }),
              ],
            ],
          );
        }
        break;

      case WorkType.task:
        if (_taskList.isEmpty) {
          content = _buildEmptyCategoryMessage('No tasks available');
        } else {
          content = ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: _taskList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FeedItemCard(
                  item: _taskList[index],
                  themeColor: themeColor,
                ),
              );
            },
          );
        }
        break;

      case WorkType.poll:
        if (_pollList.isEmpty) {
          content = _buildEmptyCategoryMessage('No polls available');
        } else {
          content = ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: _pollList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FeedItemCard(
                  item: _pollList[index],
                  themeColor: themeColor,
                ),
              );
            },
          );
        }
        break;

      case WorkType.post:
        if (_postList.isEmpty) {
          content = _buildEmptyCategoryMessage('No posts available');
        } else {
          content = ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: _postList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FeedItemCard(
                  item: _postList[index],
                  themeColor: themeColor,
                ),
              );
            },
          );
        }
        break;
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNoItems =
        _taskList.isEmpty && _pollList.isEmpty && _postList.isEmpty;

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : hasNoItems
              ? _buildEmptyState()
              : Column(
                children: [
                  // Filter chips
                  _buildFilterChips(),

                  // Divider
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),

                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      color: themeColor,
                      onRefresh: _loadCombinedFeed,
                      child: _buildFilteredContent(),
                    ),
                  ),
                ],
              ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16),
        child: FloatingActionButton(
          onPressed: _showCreateBottomSheet,
          backgroundColor: themeColor,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
