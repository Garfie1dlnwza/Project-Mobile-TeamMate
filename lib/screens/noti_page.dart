import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/services/firestore_noti_service.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:intl/intl.dart';

class NotiPage extends StatefulWidget {
  const NotiPage({super.key});

  @override
  State<NotiPage> createState() => _NotiPageState();
}

class _NotiPageState extends State<NotiPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _errorMessage;
  final FirestoreNotificationService _notificationService =
      FirestoreNotificationService();

  // Filter options
  bool _showAll = true;
  bool _showUnread = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // นับจำนวนการแจ้งเตือนที่ยังไม่ได้อ่านและอัปเดตสถานะผู้ใช้
    _notificationService.syncNotificationStatusWithCount();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You need to be logged in to view notifications';
        });
        return;
      }

      // Get notifications from Firestore
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .get();

      final List<Map<String, dynamic>> notifications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        notifications.add({'id': doc.id, ...data});
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      // นับจำนวนการแจ้งเตือนที่ยังไม่ได้อ่านและอัปเดตสถานะผู้ใช้
      await _notificationService.syncNotificationStatusWithCount();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading notifications: $e';
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      setState(() {
        final index = _notifications.indexWhere(
          (n) => n['id'] == notificationId,
        );
        if (index != -1) {
          _notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      // Handle error
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      // Update local state
      setState(() {
        for (var notification in _notifications) {
          notification['read'] = true;
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Handle error
      print('Error marking all notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    // Mark as read first
    if (!(notification['read'] ?? false)) {
      await _markAsRead(notification['id']);
    }

    // Navigate based on notification type
    switch (notification['type']) {
      case 'project_invitation':
        _navigateToProjectDetail(notification['projectId']);
        break;

      case 'task_created':
      case 'task_updated':
      case 'task_submitted':
      case 'task_approved':
      case 'task_rejected':
        _navigateToTaskDetail(notification['taskId']);
        break;

      case 'poll_created':
        _navigateToPollDetail(notification['pollId']);
        break;

      case 'post_created':
      case 'post_comment':
        _navigateToPostDetail(notification['postId']);
        break;

      case 'document_shared':
        _navigateToDocumentDetail(notification['documentId']);
        break;

      default:
        // If unknown type, just mark as read
        break;
    }
  }

  // Navigation methods
  void _navigateToProjectDetail(String? projectId) {
    if (projectId == null) return;
    // Navigate to project detail page
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailPage(projectId: projectId)));
  }

  void _navigateToTaskDetail(String? taskId) {
    if (taskId == null) return;
    // Navigate to task detail page
    // Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailPage(taskId: taskId)));
  }

  void _navigateToPollDetail(String? pollId) {
    if (pollId == null) return;
    // Navigate to poll detail page
    // Navigator.push(context, MaterialPageRoute(builder: (context) => PollDetailPage(pollId: pollId)));
  }

  void _navigateToPostDetail(String? postId) {
    if (postId == null) return;
    // Navigate to post detail page
    // Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailPage(postId: postId)));
  }

  void _navigateToDocumentDetail(String? documentId) {
    if (documentId == null) return;
    // Navigate to document detail page
    // Navigator.push(context, MaterialPageRoute(builder: (context) => DocumentDetailPage(documentId: documentId)));
  }

  // Format timestamp for displaying
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  // Get icon for notification type
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'project_invitation':
        return Icons.group_add;
      case 'task_created':
        return Icons.assignment_add;
      case 'task_updated':
        return Icons.update;
      case 'task_submitted':
        return Icons.task_alt;
      case 'task_approved':
        return Icons.check_circle;
      case 'task_rejected':
        return Icons.cancel;
      case 'poll_created':
        return Icons.poll;
      case 'post_created':
        return Icons.post_add;
      case 'post_comment':
        return Icons.comment;
      case 'document_shared':
        return Icons.file_present;
      default:
        return Icons.notifications;
    }
  }

  // Get color for notification type
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'project_invitation':
        return Colors.blue;
      case 'task_created':
        return Colors.green;
      case 'task_updated':
        return Colors.amber;
      case 'task_submitted':
        return Colors.orange;
      case 'task_approved':
        return Colors.green;
      case 'task_rejected':
        return Colors.red;
      case 'poll_created':
        return Colors.purple;
      case 'post_created':
        return Colors.indigo;
      case 'post_comment':
        return Colors.teal;
      case 'document_shared':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // Get title for notification type
  String _getNotificationTitle(String type) {
    switch (type) {
      case 'project_invitation':
        return 'Project Invitation';
      case 'task_created':
        return 'New Task';
      case 'task_updated':
        return 'Task Updated';
      case 'task_submitted':
        return 'Task Submitted';
      case 'task_approved':
        return 'Task Approved';
      case 'task_rejected':
        return 'Task Rejected';
      case 'poll_created':
        return 'New Poll';
      case 'post_created':
        return 'New Post';
      case 'post_comment':
        return 'New Comment';
      case 'document_shared':
        return 'Document Shared';
      default:
        return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter notifications based on selection
    final List<Map<String, dynamic>> filteredNotifications =
        _showUnread
            ? _notifications.where((n) => !(n['read'] ?? false)).toList()
            : _notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 1,
        actions: [
          // Only show mark all as read if there are unread notifications
          if (_notifications.any((n) => !(n['read'] ?? false)))
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Text(
                  'Filter:',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _showAll,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _showAll = true;
                        _showUnread = false;
                      });
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Unread'),
                  selected: _showUnread,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _showAll = false;
                        _showUnread = true;
                      });
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                ),
              ],
            ),
          ),

          // Notification list or status messages
          Expanded(child: _buildNotificationContent(filteredNotifications)),
        ],
      ),
    );
  }

  Widget _buildNotificationContent(List<Map<String, dynamic>> notifications) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showUnread
                  ? Icons.mark_email_read
                  : Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showUnread ? 'No unread notifications' : 'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showUnread
                  ? 'You\'ve read all your notifications'
                  : 'When you have notifications, they will appear here',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show the notification list
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final bool isRead = notification['read'] ?? false;
          final String type = notification['type'] ?? 'unknown';

          return Dismissible(
            key: Key('notification_${notification['id']}'),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              // Delete notification
              _deleteNotification(notification['id']);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: isRead ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isRead ? Colors.grey[300]! : Colors.grey[400]!,
                  width: 0.5,
                ),
              ),
              color: isRead ? Colors.grey[50] : Colors.white,
              child: InkWell(
                onTap: () => _handleNotificationTap(notification),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notification icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(type).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(type),
                          color: _getNotificationColor(type),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Notification content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title with unread indicator
                            Row(
                              children: [
                                // Unread indicator
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getNotificationColor(type),
                                    ),
                                  ),

                                // Title
                                Text(
                                  _getNotificationTitle(type),
                                  style: TextStyle(
                                    fontWeight:
                                        isRead
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // Notification message
                            Text(
                              notification['message'] ?? 'No message',
                              style: TextStyle(
                                color: Colors.grey[700],
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Timestamp and "Mark as read" option
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTimestamp(notification['timestamp']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),

                                if (!isRead)
                                  GestureDetector(
                                    onTap:
                                        () => _markAsRead(notification['id']),
                                    child: Text(
                                      'Mark as read',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
