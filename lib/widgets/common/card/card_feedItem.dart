import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/utils/date.dart';
import 'package:teammate/widgets/works/poll.dart';
import 'package:teammate/widgets/works/post.dart';
import 'package:teammate/widgets/works/task_content.dart';

class FeedItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Color themeColor;

  const FeedItemCard({super.key, required this.item, required this.themeColor});

  @override
  State<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<FeedItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    print(widget.item['data']);
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Fade-in animation
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Slide-up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String type = widget.item['type'];
    final Map<String, dynamic> data = widget.item['data'];
    final Timestamp createdAt = widget.item['createdAt'] as Timestamp;

    // Animate the card appearance
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[300]!.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.grey[400]!.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card header with minimalist design
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(
                        color: _getTypeColor(type).withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Type indicator
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getTypeColor(type).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTypeIcon(type),
                          size: 18,
                          color: _getTypeColor(type),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Type label
                      Text(
                        _getTypeLabel(type),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const Spacer(),

                      // Timestamp with icon
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatDateTime(createdAt.toDate()),
                              style: TextStyle(
                                fontSize: 12,
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

                // Card content
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(type, data),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'task':
        return TaskContent(data: data, themeColor: Colors.grey[800]!);
      case 'post':
        return PostContent(data: data, themeColor: Colors.grey[800]!);
      case 'poll':
        return PollContent(data: data, themeColor: Colors.grey[800]!);
      default:
        return const Text('Unknown content type');
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'task':
        return Colors.grey[700]!;
      case 'post':
        return Colors.grey[800]!;
      case 'poll':
        return Colors.grey[600]!;
      default:
        return Colors.grey[500]!;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'task':
        return Icons.assignment_outlined;
      case 'post':
        return Icons.article_outlined;
      case 'poll':
        return Icons.poll_outlined;
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
