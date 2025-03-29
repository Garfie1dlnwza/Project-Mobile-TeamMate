import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const PostContent({Key? key, required this.data, required this.themeColor})
    : super(key: key);

  @override
  State<PostContent> createState() => _PostContentState();
}

class _PostContentState extends State<PostContent> {
  bool _isExpanded = false;
  final User? userCreator = FirebaseAuth.instance.currentUser;

  static const int _maxLines = 3;

  @override
  void initlized() {
    print(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.data['title'] ?? '';
    final String description = widget.data['description'] ?? '';
    final String? creatorName = userCreator!.displayName;

    // Calculate if the text would overflow
    final TextSpan textSpan = TextSpan(
      text: description,
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[700],
        height: 1.5,
        letterSpacing: 0.2,
      ),
    );

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: _maxLines,
    );

    // Use MediaQuery to get screen width for measuring text
    textPainter.layout(
      maxWidth: MediaQuery.of(context).size.width - 40,
    ); // Adjust for padding
    final bool hasTextOverflow = textPainter.didExceedMaxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post author info row
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, color: Colors.grey[700]),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${creatorName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Team Member',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Post title
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Post description with Read More functionality
        if (description.isNotEmpty) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCrossFade(
                firstChild: Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                  maxLines: _maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                secondChild: Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                ),
                crossFadeState:
                    _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              if (hasTextOverflow) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        _isExpanded ? 'Show Less' : 'Read More',
                        style: TextStyle(
                          color: widget.themeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: widget.themeColor,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Interaction bar with animated effects
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInteractionButton(
                icon: Icons.emoji_emotions_outlined,
                label: 'OK',
                color: Colors.grey[700]!,
                onTap: () {},
              ),
              _buildInteractionButton(
                icon: Icons.comment_outlined,
                label: 'Comment',
                color: Colors.grey[700]!,
                onTap: () {
                  // Make sure description is fully expanded when commenting
                  if (!_isExpanded && hasTextOverflow) {
                    setState(() {
                      _isExpanded = true;
                    });
                  }
                  // Comment functionality would go here
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}
