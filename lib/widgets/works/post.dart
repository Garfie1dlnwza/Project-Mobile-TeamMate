import 'package:flutter/material.dart';

class PostContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const PostContent({Key? key, required this.data, required this.themeColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? '';
    final String description = data['description'] ?? '';
    final String imageUrl = data['image'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post title
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],

        // Post content
        Text(description, style: const TextStyle(fontSize: 15)),

        // Post image
        if (imageUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Post interaction buttons
        Row(
          children: [
            IconButton(
              onPressed: () {
                // Like post
              },
              icon: const Icon(Icons.thumb_up_alt_outlined),
              color: Colors.grey[700],
            ),
            IconButton(
              onPressed: () {
                // Comment on post
              },
              icon: const Icon(Icons.comment_outlined),
              color: Colors.grey[700],
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // View post details
              },
              child: const Text('View Details'),
            ),
          ],
        ),
      ],
    );
  }
}
