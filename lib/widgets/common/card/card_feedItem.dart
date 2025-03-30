import 'package:flutter/material.dart';
import 'package:teammate/widgets/works/document.dart';
import 'package:teammate/widgets/works/poll.dart';
import 'package:teammate/widgets/works/post.dart';
import 'package:teammate/widgets/works/task_content.dart';

class FeedItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color themeColor;

  const FeedItemCard({super.key, required this.item, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final type = item['type'];
    final data = item['data'];
    final id = item['id'];

    switch (type) {
      case 'post':
        return PostContent(data: data, themeColor: themeColor);
      case 'poll':
        return PollContent(data: data, themeColor: themeColor, pollId: id);
      case 'task':
        return TaskContent(data: data, themeColor: themeColor);
      case 'document':
        return DocumentContent(data: data, themeColor: themeColor);
      default:
        return Text('Unknown content type: $type');
    }
  }
}
