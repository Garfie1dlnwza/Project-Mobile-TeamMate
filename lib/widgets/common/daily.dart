import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/services/firestore_task_service.dart';
import 'package:teammate/screens/details/task_detail_admin_page.dart';
import 'package:intl/intl.dart';
import 'package:teammate/theme/app_colors.dart';

class DailySchedule extends StatefulWidget {
  final DateTime selectedDate;
  final Color themeColor;

  const DailySchedule({
    super.key,
    required this.selectedDate,
    this.themeColor = Colors.blue,
  });

  @override
  State<DailySchedule> createState() => _DailyScheduleState();
}

class _DailyScheduleState extends State<DailySchedule> {
  final FirestoreTaskService _taskService = FirestoreTaskService();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final int _currentHour = DateTime.now().hour;

  @override
  void initState() {
    super.initState();
    _loadTasks();

    // Scroll to current hour after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentHour();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentHour() {
    // Only scroll to current hour for today's date
    if (widget.selectedDate.year == DateTime.now().year &&
        widget.selectedDate.month == DateTime.now().month &&
        widget.selectedDate.day == DateTime.now().day) {
      // Each hour has a height of approximately 100 pixels
      // This is an estimation and might need adjustment
      const double hourHeight = 100.0;
      final double offset = _currentHour * hourHeight;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void didUpdateWidget(DailySchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadTasks();
      // Scroll to current hour if the date is today
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentHour();
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get tasks for the selected day
      final tasks = await _taskService.getTasksForDay(widget.selectedDate);

      // Add a small delay to show loading animation
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() {
        _isLoading = false;
        _tasks = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading schedule...'),
            ],
          ),
        )
        : Column(
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat(
                      'EEEE, MMMM d, yyyy',
                    ).format(widget.selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _tasks.isNotEmpty ? '${_tasks.length} tasks' : 'No tasks',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Tasks list or empty state
            _tasks.isEmpty
                ? _buildEmptyState()
                : Expanded(child: _buildSchedule()),
          ],
        );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tasks scheduled for this day',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedule() {
    // Create a 24-hour schedule with 1-hour intervals
    final List<DateTime> timeSlots = List.generate(
      24, // 24 hours in a day
      (index) => DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        index, // 0-23 hours
        0, // minutes always 0 for hourly slots
      ),
    );

    // Group tasks by hour
    Map<int, List<Map<String, dynamic>>> tasksByHour = {};
    for (var task in _tasks) {
      final Timestamp endTime = task['endTask'] as Timestamp;
      final DateTime endDateTime = endTime.toDate();
      final int hour = endDateTime.hour;

      if (!tasksByHour.containsKey(hour)) {
        tasksByHour[hour] = [];
      }

      tasksByHour[hour]!.add(task);
    }

    // Sort tasks within each hour
    tasksByHour.forEach((hour, tasks) {
      tasks.sort((a, b) {
        final Timestamp aEnd = a['endTask'] as Timestamp;
        final Timestamp bEnd = b['endTask'] as Timestamp;
        return aEnd.compareTo(bEnd);
      });
    });

    return ListView.builder(
      controller: _scrollController,
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = timeSlots[index];
        final isCurrentHour =
            DateTime.now().hour == index &&
            widget.selectedDate.day == DateTime.now().day &&
            widget.selectedDate.month == DateTime.now().month &&
            widget.selectedDate.year == DateTime.now().year;

        return TimeSlotWidget(
          time: timeSlot,
          tasks: tasksByHour[index] ?? [],
          themeColor: widget.themeColor,
          isCurrentHour: isCurrentHour,
        );
      },
    );
  }
}

class TimeSlotWidget extends StatelessWidget {
  final DateTime time;
  final List<Map<String, dynamic>> tasks;
  final Color themeColor;
  final bool isCurrentHour;

  const TimeSlotWidget({
    super.key,
    required this.time,
    required this.tasks,
    required this.themeColor,
    this.isCurrentHour = false,
  });

  @override
  Widget build(BuildContext context) {
    // Format time in 24-hour format: "00:00", "01:00", etc.
    final String timeString = DateFormat('HH:00').format(time);

    return Container(
      decoration: BoxDecoration(
        color: isCurrentHour ? Colors.yellow[50] : null,
        border:
            isCurrentHour
                ? Border(left: BorderSide(color: themeColor, width: 3))
                : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time indicator
          Container(
            width: 80,
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            color: isCurrentHour ? Colors.yellow[100] : Colors.grey[50],
            child: Text(
              timeString,
              style: TextStyle(
                fontSize: 15,
                color: isCurrentHour ? Colors.black87 : Colors.grey[700],
                fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),

          // Time slot content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tasks for this time slot
                  if (tasks.isNotEmpty)
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                            right: 16,
                            bottom: 8,
                            left: 16,
                          ),
                          child: TaskEventCard(
                            task: tasks[index],
                            themeColor: themeColor,
                          ),
                        );
                      },
                    )
                  else
                    const SizedBox(
                      height: 50,
                    ), // Empty space for slots with no events
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskEventCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final Color themeColor;

  const TaskEventCard({super.key, required this.task, required this.themeColor});

  Color _getEventColor(Map<String, dynamic> task) {
    final bool isSubmitted = task['isSubmit'] ?? false;
    final bool isApproved = task['isApproved'] ?? false;
    final bool isRejected = task['isRejected'] ?? false;
    final Timestamp endTask = task['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endTask.toDate();
    final bool isOverdue =
        DateTime.now().isAfter(dueDate) && !isApproved && !isSubmitted;
    final Duration timeLeft = dueDate.difference(DateTime.now());
    final bool isUrgent =
        timeLeft.inDays <= 2 && !isApproved && !isSubmitted && !isRejected;

    if (isApproved) return Colors.green[100]!;
    if (isRejected) return Colors.red[100]!;
    if (isSubmitted) return Colors.blue[100]!;
    if (isOverdue) return Colors.red[50]!;
    if (isUrgent) return Colors.orange[50]!;

    // Default colors based on department or task type
    final String departmentId = task['departmentId'] ?? '';

    // Simple hash function to generate consistent colors based on departmentId
    if (departmentId.isNotEmpty) {
      final int hash = departmentId.hashCode.abs() % 6;
      switch (hash) {
        case 0:
          return Colors.blue[50]!;
        case 1:
          return Colors.orange[50]!;
        case 2:
          return Colors.purple[50]!;
        case 3:
          return Colors.green[50]!;
        case 4:
          return Colors.teal[50]!;
        case 5:
          return Colors.indigo[50]!;
        default:
          return Colors.grey[50]!;
      }
    }

    return Colors.grey[50]!;
  }

  Color _getBorderColor(Map<String, dynamic> task) {
    final bool isSubmitted = task['isSubmit'] ?? false;
    final bool isApproved = task['isApproved'] ?? false;
    final bool isRejected = task['isRejected'] ?? false;
    final Timestamp endTask = task['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endTask.toDate();
    final bool isOverdue =
        DateTime.now().isAfter(dueDate) && !isApproved && !isSubmitted;
    final Duration timeLeft = dueDate.difference(DateTime.now());
    final bool isUrgent =
        timeLeft.inDays <= 2 && !isApproved && !isSubmitted && !isRejected;

    if (isApproved) return Colors.green;
    if (isRejected) return Colors.red;
    if (isSubmitted) return Colors.blue;
    if (isOverdue) return Colors.red[300]!;
    if (isUrgent) return Colors.orange;

    return Colors.grey[300]!;
  }

  Future<String> _getDepartmentName(String departmentId) async {
    try {
      final FirestoreTaskService taskService = FirestoreTaskService();
      return await taskService.getDepartmentName(departmentId);
    } catch (e) {
      print('Error getting department name: $e');
      return 'Unknown Department';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = task['taskTitle'] ?? 'Untitled Task';
    final Timestamp endTime = task['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endTime.toDate();
    final String departmentId = task['departmentId'] ?? '';

    return GestureDetector(
      onTap: () async {
        // Check if user is admin or head
        final currentUser = FirebaseAuth.instance.currentUser;
        bool isAdminOrHead = false;

        if (currentUser != null) {
          try {
            // Check if user is in the admins array of the department
            final snapshot =
                await FirebaseFirestore.instance
                    .collection('departments')
                    .doc(departmentId)
                    .get();

            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>;
              final List<dynamic> admins = data['admins'] ?? [];
              isAdminOrHead = admins.contains(currentUser.uid);
            }
          } catch (e) {
            print('Error checking user roles: $e');
          }
        }

        // Navigate to task details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TaskDetailsAdminPage(
                  data: task,
                  themeColor: themeColor,
                  isAdminOrHead: isAdminOrHead,
                ),
          ),
        ).then((_) {
          // Refresh the page when returning from task details
          if (context.findAncestorStateOfType<_DailyScheduleState>() != null) {
            context
                .findAncestorStateOfType<_DailyScheduleState>()!
                ._loadTasks();
          }
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _getEventColor(task),
          border: Border(
            left: BorderSide(color: _getBorderColor(task), width: 4),
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time
                  Text(
                    DateFormat('HH:mm').format(dueDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Task title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Department name
                  FutureBuilder<String>(
                    future: _getDepartmentName(departmentId),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'Loading department...',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      );
                    },
                  ),

                  // Space for the status badge
                  if (task['isSubmit'] == true ||
                      task['isApproved'] == true ||
                      task['isRejected'] == true)
                    const SizedBox(height: 20),
                ],
              ),
            ),

            // Status badge
            if (task['isSubmit'] == true ||
                task['isApproved'] == true ||
                task['isRejected'] == true)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor(task),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(task),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBadgeColor(Map<String, dynamic> task) {
    if (task['isApproved'] == true) return Colors.green;
    if (task['isRejected'] == true) return Colors.red;
    if (task['isSubmit'] == true) return Colors.blue;

    return Colors.grey;
  }

  String _getStatusText(Map<String, dynamic> task) {
    if (task['isApproved'] == true) return 'APPROVED';
    if (task['isRejected'] == true) return 'REJECTED';
    if (task['isSubmit'] == true) return 'SUBMITTED';

    return 'PENDING';
  }
}
