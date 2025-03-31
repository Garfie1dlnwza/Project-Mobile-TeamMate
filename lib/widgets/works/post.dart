import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/services/firestore_user_service.dart';
import 'package:teammate/services/file_attachment_service.dart';
import 'package:teammate/widgets/common/button/button_ok_reaction.dart';
import 'package:teammate/widgets/common/comment.dart';
import 'package:teammate/widgets/common/file/file_attachment_widget%20.dart';


class PostContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const PostContent({super.key, required this.data, required this.themeColor});

  @override
  State<PostContent> createState() => _PostContentState();
}

class _PostContentState extends State<PostContent> {
  bool _isExpanded = false;
  bool _showComments = false;
  final FirestoreUserService _userService = FirestoreUserService();
  final List<FileAttachment> _attachments = [];
  bool _loadingAttachments = false;
  static const int _maxLines = 3;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    // Check for image attachments first
    if (widget.data['image'] != null &&
        widget.data['image'].toString().isNotEmpty) {
      setState(() {
        _attachments.add(
          FileAttachment(
            fileName: 'Image',
            fileType: 'IMAGE',
            downloadUrl: widget.data['image'],
            isImage: true,
          ),
        );
      });
    }

    // Check for file attachments
    if (widget.data['file'] != null &&
        widget.data['file'].toString().isNotEmpty) {
      final String url = widget.data['file'];
      final String fileName = url.split('/').last.split('?').first;
      final String fileType = fileName.split('.').last.toUpperCase();
      final bool isImage = [
        'JPG',
        'JPEG',
        'PNG',
        'GIF',
        'WEBP',
        'BMP',
      ].contains(fileType);

      setState(() {
        _attachments.add(
          FileAttachment(
            fileName: fileName,
            fileType: fileType,
            downloadUrl: url,
            isImage: isImage,
          ),
        );
      });
    }

    // Check for new format attachments array
    if (widget.data['attachments'] != null &&
        widget.data['attachments'] is List &&
        (widget.data['attachments'] as List).isNotEmpty) {
      setState(() {
        _loadingAttachments = true;
      });

      try {
        List<dynamic> attachmentsData = widget.data['attachments'] as List;

        for (var item in attachmentsData) {
          if (item is String) {
            // Legacy format: URL only
            final String url = item;
            final String fileName = url.split('/').last.split('?').first;
            final String fileType = fileName.split('.').last.toUpperCase();
            final bool isImage = [
              'JPG',
              'JPEG',
              'PNG',
              'GIF',
              'WEBP',
              'BMP',
            ].contains(fileType);

            _attachments.add(
              FileAttachment(
                fileName: fileName,
                fileType: fileType,
                downloadUrl: url,
                isImage: isImage,
              ),
            );
          } else if (item is Map<String, dynamic>) {
            // New format: Map with details
            _attachments.add(
              FileAttachment(
                fileName: item['fileName'],
                fileSize: item['fileSize'],
                fileType: item['fileType'],
                downloadUrl: item['downloadUrl'],
                isImage: item['isImage'] ?? false,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error loading attachments: $e');
      } finally {
        if (mounted) {
          setState(() {
            _loadingAttachments = false;
          });
        }
      }
    }
  }

  // Toggle comments function
  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
      // When showing comments, consider expanding the text if not already expanded
      if (_showComments && !_isExpanded) {
        _isExpanded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.data['title'] ?? '';
    final String description = widget.data['description'] ?? '';
    final String creatorId = widget.data['creator'] ?? '';
    final String postId = widget.data['id'] ?? '';

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
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 40);
    final bool hasTextOverflow = textPainter.didExceedMaxLines;

    // Wrap content with Material and InkWell for tap effect
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleComments, // Call toggle function when post is tapped
        splashColor: widget.themeColor.withOpacity(0.05),
        highlightColor: widget.themeColor.withOpacity(0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post author info row - Show the creator
            FutureBuilder<String?>(
              future: _userService.findNameById(creatorId),
              builder: (context, snapshot) {
                final String creatorName = snapshot.data ?? 'Unknown User';

                return Row(
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
                          creatorName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Team Member',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Add created time if available
                    if (widget.data['createdAt'] != null)
                      Text(
                        _formatTimestamp(widget.data['createdAt']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                );
              },
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
                    // Use Material + InkWell to prevent parent tap from triggering
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Toggle text expansion state
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Display attachments if available
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._attachments.map(
                (attachment) => FileAttachmentWidget(
                  attachment: attachment,
                  themeColor: widget.themeColor,
                  showRemoveOption: false,
                ),
              ),
              const SizedBox(height: 8),
            ] else if (_loadingAttachments) ...[
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.themeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Interaction bar with OK button and comment toggle
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // OK reaction button
                  if (postId.isNotEmpty)
                    Material(
                      color: Colors.transparent,
                      child: OkReactionButton(
                        contentId: postId,
                        contentType: 'post',
                        themeColor: widget.themeColor,
                      ),
                    ),

                  // Comment button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleComments,
                      borderRadius: BorderRadius.circular(8),
                      splashColor: widget.themeColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 18,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Comment',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Comments section
            if (_showComments && postId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(color: Colors.grey[200]),
              const SizedBox(height: 8),
              // Wrap CommentWidget with Material to prevent taps from affecting parent
              Material(
                color: Colors.transparent,
                child: CommentWidget(
                  contentId: postId,
                  contentType: 'post',
                  themeColor: widget.themeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
