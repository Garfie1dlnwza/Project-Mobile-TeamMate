import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:teammate/screens/details/task_detail_admin_page.dart';

import 'package:teammate/services/firestore_department_service.dart';
import 'package:teammate/services/firestore_task_service.dart';
import 'package:teammate/widgets/common/calendar.dart';
import 'package:teammate/widgets/common/header_bar.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();
  final FirestoreTaskService _taskService = FirestoreTaskService();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _checkUserRoleAndNavigate(
    BuildContext context,
    Map<String, dynamic> task,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    final departmentId = task['departmentId'];

    // Fetch department data to find projectId
    final departmentDoc =
        await FirebaseFirestore.instance
            .collection('departments')
            .doc(departmentId)
            .get();

    final departmentData = departmentDoc.data() as Map<String, dynamic>;
    final projectId = departmentData['projectId'];

    bool isAdminOrHead = false;

    try {
      // Check if user is project head
      final projectDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(projectId)
              .get();

      if (projectDoc.exists) {
        final projectData = projectDoc.data();
        if (projectData != null &&
            projectData.containsKey('headId') &&
            projectData['headId'] == userId) {
          isAdminOrHead = true;
        }
      }

      // Check if user is department admin
      if (!isAdminOrHead &&
          departmentData.containsKey('admins') &&
          departmentData['admins'] is List &&
          (departmentData['admins'] as List).contains(userId)) {
        isAdminOrHead = true;
      }
    } catch (e) {
      print('Error checking user role: $e');
    }

    // Navigate to the appropriate page based on role
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskDetailsAdminPage(
              data: task,
              themeColor: Colors.grey[800]!,
              isAdminOrHead: isAdminOrHead,
            ),
      ),
    ).then((_) => _loadTasks());
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _tasks = [];
        });
        return;
      }

      // Format the selected date for Firestore query
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        23,
        59,
        59,
      );

      List<String> departmentIds = await _departmentService
          .getDepartmentIdsByUid(uid);

      print("Date range: $startOfDay to $endOfDay");
      print("Department IDs: $departmentIds");

      // Get tasks for all user departments
      List<Map<String, dynamic>> allTasks = await _taskService
          .getTasksByDateAndDepartments(
            departmentIds: departmentIds,
            startDate: startOfDay,
            endDate: endOfDay,
          );

      // Sort tasks by due time
      allTasks.sort((a, b) {
        final aTime = (a['endTask'] as Timestamp).toDate();
        final bTime = (b['endTask'] as Timestamp).toDate();
        return aTime.compareTo(bTime);
      });

      setState(() {
        _tasks = allTasks;
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

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headbar(title: widget.title),
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
       
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Calendar(
              onDateSelect: _onDateSelected,
              selectedDate: _selectedDate,
            ),
          ),

          // Tasks section
          Expanded(child: _buildTasksSection()),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    final formattedDate = DateFormat('EEEE, MMMM d').format(_selectedDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 30, 0, 0),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(92, 0, 0, 0).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "My Tasks",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Tasks list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _tasks.isEmpty
                    ? _buildEmptyState()
                    : _buildTasksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // ปรับปรุงข้อความให้เหมาะสมกับวันที่ผู้ใช้เลือก
    String message = "";
    String submessage = "";

    if (_selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day) {
      message = "No tasks for today";
      submessage = "Enjoy your free time!";
    } else if (_selectedDate.isBefore(DateTime.now())) {
      message = "No tasks on this day";
      submessage = "This day has already passed";
    } else {
      message = "No tasks scheduled";
      submessage =
          "You have no tasks for ${DateFormat('EEEE, MMMM d').format(_selectedDate)}";
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            submessage,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return ListView.builder(
      itemCount: _tasks.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final bool isSubmitted = task['isSubmit'] ?? false;
    final bool isApproved = task['isApproved'] ?? false;
    final bool isRejected = task['isRejected'] ?? false;
    final Timestamp endDate = task['endTask'];
    final DateTime dueTime = endDate.toDate();
    final bool isOverdue =
        DateTime.now().isAfter(dueTime) && !isApproved && !isSubmitted;

    // Calculate time remaining
    final Duration timeRemaining = dueTime.difference(DateTime.now());
    final bool isPastDue = timeRemaining.isNegative;

    // Determine task status and color
    String status;
    Color statusColor;

    if (isApproved) {
      status = 'Completed';
      statusColor = Colors.green;
    } else if (isRejected) {
      status = 'Rejected';
      statusColor = Colors.red[700]!;
    } else if (isSubmitted) {
      status = 'Submitted';
      statusColor = Colors.blue[600]!;
    } else if (isOverdue) {
      status = 'Overdue';
      statusColor = Colors.red[600]!;
    } else {
      status = 'Pending';
      statusColor = Colors.orange[600]!;
    }

    // Format time
    final timeFormat = DateFormat('h:mm a');
    final taskTime = timeFormat.format(dueTime);

    // Format time remaining text
    String timeRemainingText = '';
    if (!isApproved && !isRejected) {
      if (isPastDue) {
        final Duration overdue = Duration(
          milliseconds: timeRemaining.inMilliseconds.abs(),
        );
        if (overdue.inDays > 0) {
          timeRemainingText =
              'Overdue by ${overdue.inDays} ${overdue.inDays == 1 ? 'day' : 'days'}';
        } else if (overdue.inHours > 0) {
          timeRemainingText =
              'Overdue by ${overdue.inHours} ${overdue.inHours == 1 ? 'hour' : 'hours'}';
        } else {
          timeRemainingText =
              'Overdue by ${overdue.inMinutes} ${overdue.inMinutes == 1 ? 'minute' : 'minutes'}';
        }
      } else {
        if (timeRemaining.inDays > 0) {
          timeRemainingText =
              '${timeRemaining.inDays} ${timeRemaining.inDays == 1 ? 'day' : 'days'} left';
        } else if (timeRemaining.inHours > 0) {
          timeRemainingText =
              '${timeRemaining.inHours} ${timeRemaining.inHours == 1 ? 'hour' : 'hours'} left';
        } else {
          timeRemainingText =
              '${timeRemaining.inMinutes} ${timeRemaining.inMinutes == 1 ? 'minute' : 'minutes'} left';
        }
      }
    }

    // Determine progress color based on time remaining
    Color timeProgressColor;
    double progressValue;

    if (isApproved) {
      timeProgressColor = Colors.green;
      progressValue = 1.0;
    } else if (isRejected) {
      timeProgressColor = Colors.red[300]!;
      progressValue = 1.0;
    } else if (isSubmitted) {
      timeProgressColor = Colors.blue[400]!;
      progressValue = 1.0;
    } else if (isPastDue) {
      timeProgressColor = Colors.red[400]!;
      progressValue = 1.0;
    } else {
      // Calculate progress for remaining time (using 3 days as 100%)
      final int totalHours = 72; // 3 days in hours
      final int remainingHours = timeRemaining.inHours;
      progressValue = 1.0 - (remainingHours / totalHours).clamp(0.0, 1.0);

      if (progressValue > 0.8) {
        timeProgressColor = Colors.red[400]!;
      } else if (progressValue > 0.6) {
        timeProgressColor = Colors.orange[400]!;
      } else if (progressValue > 0.4) {
        timeProgressColor = Colors.amber[400]!;
      } else {
        timeProgressColor = Colors.green[400]!;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _checkUserRoleAndNavigate(context, task);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and chevron
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task['taskTitle'] ?? 'Untitled Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),

              const SizedBox(height: 10),

              // Description
              if (task['taskDescription'] != null &&
                  task['taskDescription'].isNotEmpty)
                Text(
                  task['taskDescription'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Time remaining progress bar
              if (!isApproved && !isRejected)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeRemainingText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                isPastDue ? Colors.red[600] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          taskTime,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isPastDue ? Colors.red[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 4,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          timeProgressColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Status and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),

                  // Time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isOverdue ? Colors.red[400] : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM').format(dueTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
