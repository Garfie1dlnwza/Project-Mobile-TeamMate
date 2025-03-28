import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/utils/date.dart';
import 'package:teammate/widgets/works/poll.dart';
import 'package:teammate/widgets/works/post.dart';
import 'package:teammate/widgets/works/task.dart';

class FeedItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color themeColor;

  const FeedItemCard({Key? key, required this.item, required this.themeColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String type = item['type'];
    final Map<String, dynamic> data = item['data'];
    final Timestamp createdAt = item['createdAt'] as Timestamp;

    // Card container with modern styling
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getTypeColor(type).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: _getTypeColor(type).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header with gradient, icon, type label, and date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTypeColor(type).withOpacity(0.15),
                  _getTypeColor(type).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _buildTypeIndicator(type),
                const SizedBox(width: 12),
                Text(
                  _getTypeLabel(type),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(type),
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatDateTime(createdAt.toDate()),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card content with subtle divider
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtle divider
                Container(
                  height: 1,
                  color: _getTypeColor(type).withOpacity(0.03),
                ),

                // Content padding
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(type, data),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIndicator(String type) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getTypeColor(type).withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(_getTypeIcon(type), size: 18, color: _getTypeColor(type)),
    );
  }

  Widget _buildContent(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'task':
        return TaskContent(data: data, themeColor: themeColor);
      case 'post':
        return PostContent(data: data, themeColor: themeColor);
      case 'poll':
        return PollContent(data: data, themeColor: themeColor);
      default:
        return const Text('Unknown content type');
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'task':
        return Color(0xFF5C6BC0);
      case 'post':
        return Color(0xFF26A69A);
      case 'poll':
        return Color(0xFF8E24AA);
      default:
        return Color(0xFF78909C);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'task':
        return Icons.task_alt;
      case 'post':
        return Icons.article_rounded;
      case 'poll':
        return Icons.poll_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'task':
        return 'Task';
      case 'post':
        return 'Post';
      case 'poll':
        return 'Poll';
      default:
        return 'Item';
    }
  }
}
