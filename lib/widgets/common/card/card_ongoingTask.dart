import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:teammate/screens/details/task_detail_page.dart';
import 'package:teammate/services/firestore_task_service.dart';
import 'package:teammate/utils/date.dart';

enum TaskFilter { all, ongoing, completed, overdue, urgent }

class CardOngoingTasks extends StatefulWidget {
  final Map<String, dynamic> data;

  const CardOngoingTasks({super.key, required this.data});

  @override
  State<CardOngoingTasks> createState() => _CardOngoingTasksState();
}

class _CardOngoingTasksState extends State<CardOngoingTasks> {
  final FirestoreTaskService _taskService = FirestoreTaskService();

  // Colors
  final Color themeColor = Colors.grey[800]!;
  final Map<TaskFilter, Color> filterColors = {
    TaskFilter.all: Colors.grey[700]!,
    TaskFilter.ongoing: Colors.blue[700]!,
    TaskFilter.completed: Colors.green[700]!,
    TaskFilter.overdue: Colors.red[700]!,
    TaskFilter.urgent: Colors.orange[700]!,
  };

  final Map<String, String> _departmentNames = {};

  bool _isLoading = true;
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  String? _errorMessage;
  TaskFilter _currentFilter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _loadAllTasks();
    _loadDepartmentNames();
  }

  Future<void> _loadDepartmentNames() async {
    try {
      // Get departmentIds from the data
      List<String> departmentIds = [];
      if (widget.data.containsKey('departments') &&
          widget.data['departments'] is List) {
        departmentIds = List<String>.from(widget.data['departments']);
      }

      // If no departments, try to use the current department
      if (departmentIds.isEmpty && widget.data.containsKey('id')) {
        departmentIds.add(widget.data['id']);
      }

      // Load department names
      for (String departmentId in departmentIds) {
        FirebaseFirestore.instance
            .collection('departments')
            .doc(departmentId)
            .get()
            .then((doc) {
              if (doc.exists && doc.data() != null) {
                final data = doc.data()!;
                setState(() {
                  _departmentNames[departmentId] =
                      data['name'] ?? 'Unknown Department';
                });
              }
            });
      }
    } catch (e) {
      debugPrint('Error loading department names: $e');
    }
  }

  Future<void> _loadAllTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _allTasks = [];
      });

      // Get departmentIds from the data
      List<String> departmentIds = [];
      if (widget.data.containsKey('departments') &&
          widget.data['departments'] is List) {
        departmentIds = List<String>.from(widget.data['departments']);
      }

      // If no departments, try to use the current department
      if (departmentIds.isEmpty && widget.data.containsKey('id')) {
        departmentIds.add(widget.data['id']);
      }

      // Load tasks for each department
      for (String departmentId in departmentIds) {
        _taskService.getTaskbyDepartmentID(departmentId).listen((
          tasksSnapshot,
        ) {
          _updateTaskList(tasksSnapshot, departmentId);
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      setState(() {
        _errorMessage = 'Failed to load tasks';
        _isLoading = false;
      });
    }
  }

  void _updateTaskList(QuerySnapshot snapshot, String departmentId) {
    List<Map<String, dynamic>> newTasks = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Include all tasks (both ongoing and completed)
      newTasks.add({
        'id': doc.id,
        'type': 'task',
        'data': {
          ...data,
          'departmentId': departmentId, // Ensure departmentId is included
        },
        'createdAt': data['createdAt'] ?? Timestamp.now(),
      });
    }

    setState(() {
      // Add new tasks
      _allTasks = [..._allTasks, ...newTasks];

      // Sort by due date (endTask)
      _allTasks.sort((a, b) {
        final Timestamp aTime = a['data']['endTask'] as Timestamp;
        final Timestamp bTime = b['data']['endTask'] as Timestamp;
        return aTime.compareTo(bTime); // Ascending order - most urgent first
      });

      // Apply current filter
      _applyFilter(_currentFilter);

      _isLoading = false;
    });
  }

  void _applyFilter(TaskFilter filter) {
    setState(() {
      _currentFilter = filter;

      switch (filter) {
        case TaskFilter.all:
          _filteredTasks = List.from(_allTasks);
          break;
        case TaskFilter.ongoing:
          _filteredTasks =
              _allTasks
                  .where((task) => !(task['data']['isSubmit'] ?? false))
                  .toList();
          break;
        case TaskFilter.completed:
          _filteredTasks =
              _allTasks
                  .where((task) => task['data']['isSubmit'] ?? false)
                  .toList();
          break;
        case TaskFilter.overdue:
          _filteredTasks =
              _allTasks.where((task) {
                final bool isSubmitted = task['data']['isSubmit'] ?? false;
                if (isSubmitted) return false;

                final Timestamp endTimestamp =
                    task['data']['endTask'] ?? Timestamp.now();
                final DateTime dueDate = endTimestamp.toDate();
                return DateTime.now().isAfter(dueDate);
              }).toList();
          break;
        case TaskFilter.urgent:
          _filteredTasks =
              _allTasks.where((task) {
                final bool isSubmitted = task['data']['isSubmit'] ?? false;
                if (isSubmitted) return false;

                final Timestamp endTimestamp =
                    task['data']['endTask'] ?? Timestamp.now();
                final DateTime dueDate = endTimestamp.toDate();
                final Duration timeLeft = dueDate.difference(DateTime.now());
                return timeLeft.inDays <= 2 && !DateTime.now().isAfter(dueDate);
              }).toList();
          break;
      }
    });
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(TaskFilter.all, 'All'),
          const SizedBox(width: 10),
          _buildFilterChip(TaskFilter.ongoing, 'Ongoing'),
          const SizedBox(width: 10),
          _buildFilterChip(TaskFilter.completed, 'Completed'),
          const SizedBox(width: 10),
          _buildFilterChip(TaskFilter.urgent, 'Urgent'),
          const SizedBox(width: 10),
          _buildFilterChip(TaskFilter.overdue, 'Overdue'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TaskFilter filter, String label) {
    final bool isSelected = _currentFilter == filter;
    final Color filterColor = filterColors[filter] ?? Colors.grey[700]!;

    return GestureDetector(
      onTap: () => _applyFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? filterColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? filterColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? filterColor : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Expanded(
        child: Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_errorMessage',
                style: TextStyle(color: Colors.red[400]),
              ),
            ],
          ),
        ),
      );
    }

    if (_allTasks.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_outlined, color: Colors.grey[400], size: 48),
              const SizedBox(height: 16),
              Text(
                'No tasks found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          _buildFilterChips(),

          // Task count
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: filterColors[_currentFilter]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredTasks.length} tasks',
                    style: TextStyle(
                      color: filterColors[_currentFilter],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Task list
          Expanded(
            child:
                _filteredTasks.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getEmptyStateIcon(),
                            color: Colors.grey[400],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_currentFilter.name} tasks found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(right: 20, bottom: 20),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final taskData = _filteredTasks[index]['data'];
                        return _buildTaskCard(context, taskData);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_currentFilter) {
      case TaskFilter.completed:
        return Icons.check_circle_outline;
      case TaskFilter.overdue:
        return Icons.watch_later_outlined;
      case TaskFilter.urgent:
        return Icons.priority_high_outlined;
      default:
        return Icons.task_outlined;
    }
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> data) {
    final String title = data['taskTitle'] ?? 'Untitled Task';
    final bool isSubmitted = data['isSubmit'] ?? false;
    final Timestamp endDate = data['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endDate.toDate();
    final bool isOverdue = DateTime.now().isAfter(dueDate) && !isSubmitted;
    final Duration timeLeft = dueDate.difference(DateTime.now());
    final bool isUrgent = timeLeft.inDays <= 2 && !isSubmitted;

    // Get department name
    final String departmentId = data['departmentId'] ?? '';
    final String departmentName = _departmentNames[departmentId] ?? '';

    // Determine status and colors
    String statusText;
    Color statusColor;

    if (isSubmitted) {
      statusText = 'Completed';
      statusColor = Colors.green[700]!;
    } else if (isOverdue) {
      statusText = 'Overdue';
      statusColor = Colors.red[700]!;
    } else if (isUrgent) {
      statusText = 'Urgent';
      statusColor = Colors.orange[700]!;
    } else {
      statusText = 'Ongoing';
      statusColor = Colors.blue[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 40, 40, 40).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),

        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        TaskDetailsPage(data: data, themeColor: themeColor),
              ),
            ).then((_) => _loadAllTasks());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with status and due date
                Row(
                  children: [
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Due date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: isOverdue ? Colors.red[400] : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatDateShort(dueDate),
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isOverdue ? Colors.red[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Task title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[850],
                    decoration: isSubmitted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Description if available
                if (data['taskDescription'] != null &&
                    data['taskDescription'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    data['taskDescription'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      decoration:
                          isSubmitted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Bottom row with department and progress
                Row(
                  children: [
                    // Department badge (only if department name exists)
                    if (departmentName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          departmentName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Progress indicator or completion
                    Expanded(
                      child:
                          isSubmitted
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 16,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Progress bar
                                  LinearProgressIndicator(
                                    value: _calculateProgress(data),
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isOverdue
                                          ? Colors.red[400]!
                                          : isUrgent
                                          ? Colors.orange[400]!
                                          : Colors.blue[600]!,
                                    ),
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                  ),

                                  const SizedBox(height: 4),

                                  // Time remaining
                                  Text(
                                    _getTimeRemainingText(timeLeft, isOverdue),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          isOverdue
                                              ? Colors.red[400]
                                              : isUrgent
                                              ? Colors.orange[600]
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _calculateProgress(Map<String, dynamic> data) {
    // If there's a direct progress value, use it
    if (data.containsKey('progress') && data['progress'] is num) {
      return (data['progress'] as num).toDouble() / 100;
    }

    // Otherwise calculate based on time
    Timestamp startTask = data['startTask'] ?? Timestamp.now();
    Timestamp endTask = data['endTask'] ?? Timestamp.now();

    DateTime startDate = startTask.toDate();
    DateTime endDate = endTask.toDate();
    DateTime now = DateTime.now();

    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;

    int totalDuration = endDate.difference(startDate).inSeconds;
    int elapsedDuration = now.difference(startDate).inSeconds;

    if (totalDuration <= 0) return 0.0;
    return elapsedDuration / totalDuration;
  }

  String _getTimeRemainingText(Duration timeLeft, bool isOverdue) {
    if (isOverdue) {
      Duration overdue = -timeLeft;
      if (overdue.inDays > 0) {
        return '${overdue.inDays}d overdue';
      } else if (overdue.inHours > 0) {
        return '${overdue.inHours}h overdue';
      } else {
        return '${overdue.inMinutes}m overdue';
      }
    } else {
      if (timeLeft.inDays > 0) {
        return '${timeLeft.inDays}d remaining';
      } else if (timeLeft.inHours > 0) {
        return '${timeLeft.inHours}h remaining';
      } else {
        return '${timeLeft.inMinutes}m remaining';
      }
    }
  }
}
