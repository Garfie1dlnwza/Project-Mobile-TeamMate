import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/screens/details/detail_task.dart';
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
  final Color themeColor = Colors.grey[800]!;
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
      // print(widget.data);
      List<String> departmentIds = [];
      if (widget.data.containsKey('departments') &&
          widget.data['departments'] is List) {
        departmentIds = List<String>.from(widget.data['departments']);
      }
      // print('departmentId :$departmentIds');
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(TaskFilter.all, 'All', Icons.view_list),
          const SizedBox(width: 8),
          _buildFilterChip(
            TaskFilter.ongoing,
            'Ongoing',
            Icons.pending_actions,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            TaskFilter.completed,
            'Completed',
            Icons.check_circle_outline,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(TaskFilter.urgent, 'Urgent', Icons.priority_high),
          const SizedBox(width: 8),
          _buildFilterChip(TaskFilter.overdue, 'Overdue', Icons.watch_later),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TaskFilter filter, String label, IconData icon) {
    final bool isSelected = _currentFilter == filter;

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
        if (selected) {
          _applyFilter(filter);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Error: $_errorMessage',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      );
    }

    if (_allTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No tasks found',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          // Filter chips
          _buildFilterChips(),

          // Task count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredTasks.length} ${_currentFilter.name} task${_filteredTasks.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
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
                      child: Text(
                        'No ${_currentFilter.name} tasks found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
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
    final String departmentName =
        _departmentNames[departmentId] ?? 'Unknown Department';

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      TaskDetailsPage(data: data, themeColor: themeColor),
            ),
          ).then((_) {
            // Refresh tasks when returning from details page
            _loadAllTasks();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and due date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(
                        isSubmitted,
                        isOverdue,
                        isUrgent,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPriorityText(isSubmitted, isOverdue, isUrgent),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color:
                        isOverdue
                            ? Colors.red[400]
                            : isSubmitted
                            ? Colors.green[600]
                            : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDateShort(dueDate),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isOverdue
                              ? Colors.red[400]
                              : isSubmitted
                              ? Colors.green[600]
                              : Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Department tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.business, size: 12, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      departmentName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Task title
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  decoration: isSubmitted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Description preview if available
              if (data['taskDescription'] != null &&
                  data['taskDescription'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  data['taskDescription'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    decoration: isSubmitted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),

              // Progress indicator (only for non-completed tasks)
              if (!isSubmitted) ...[
                LinearProgressIndicator(
                  value: _calculateProgress(data),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(isSubmitted, isOverdue, isUrgent),
                  ),
                ),

                const SizedBox(height: 4),

                // Time remaining
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _getTimeRemainingText(timeLeft, isOverdue),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color:
                            isOverdue
                                ? Colors.red[400]
                                : isUrgent
                                ? Colors.orange[700]
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Completed indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.check_circle,
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
                ),
              ],

              // View details button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TaskDetailsPage(
                              data: data,
                              themeColor: themeColor,
                            ),
                      ),
                    ).then((_) => _loadAllTasks());
                  },
                  icon: Icon(Icons.remove_red_eye, size: 16, color: themeColor),
                  label: Text(
                    'View Details',
                    style: TextStyle(color: themeColor, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateProgress(Map<String, dynamic> data) {
    if (data.containsKey('progress') && data['progress'] is num) {
      return (data['progress'] as num).toDouble() / 100;
    }

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

  Color _getPriorityColor(bool isSubmitted, bool isOverdue, bool isUrgent) {
    if (isSubmitted) return Colors.green[600]!;
    if (isOverdue) return Colors.red[600]!;
    if (isUrgent) return Colors.orange[600]!;
    return Colors.grey[700]!;
  }

  Color _getProgressColor(bool isSubmitted, bool isOverdue, bool isUrgent) {
    if (isSubmitted) return Colors.green[500]!;
    if (isOverdue) return Colors.red[400]!;
    if (isUrgent) return Colors.orange[400]!;
    return Colors.blue[500]!;
  }

  String _getPriorityText(bool isSubmitted, bool isOverdue, bool isUrgent) {
    if (isSubmitted) return 'COMPLETED';
    if (isOverdue) return 'OVERDUE';
    if (isUrgent) return 'URGENT';
    return 'ONGOING';
  }

  String _getTimeRemainingText(Duration timeLeft, bool isOverdue) {
    if (isOverdue) {
      Duration overdue = -timeLeft;
      if (overdue.inDays > 0) {
        return 'Overdue by ${overdue.inDays} ${overdue.inDays == 1 ? 'day' : 'days'}';
      } else if (overdue.inHours > 0) {
        return 'Overdue by ${overdue.inHours} ${overdue.inHours == 1 ? 'hour' : 'hours'}';
      } else {
        return 'Overdue by ${overdue.inMinutes} ${overdue.inMinutes == 1 ? 'minute' : 'minutes'}';
      }
    } else {
      if (timeLeft.inDays > 0) {
        return '${timeLeft.inDays} ${timeLeft.inDays == 1 ? 'day' : 'days'} remaining';
      } else if (timeLeft.inHours > 0) {
        return '${timeLeft.inHours} ${timeLeft.inHours == 1 ? 'hour' : 'hours'} remaining';
      } else {
        return '${timeLeft.inMinutes} ${timeLeft.inMinutes == 1 ? 'minute' : 'minutes'} remaining';
      }
    }
  }
}
