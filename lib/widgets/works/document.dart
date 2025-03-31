import 'package:flutter/material.dart';
import 'package:teammate/utils/date.dart';
import 'package:teammate/widgets/common/file/file_attachment_widget%20.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:teammate/services/file_attachment_service.dart';

class DocumentContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const DocumentContent({
    super.key,
    required this.data,
    required this.themeColor,
  });

  @override
  State<DocumentContent> createState() => _DocumentContentState();
}

class _DocumentContentState extends State<DocumentContent> {
  final List<FileAttachment> _attachments = [];
  bool _loadingAttachments = false;
  bool _isExpanded = false;
  static const int _maxLines = 3;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    setState(() {
      _loadingAttachments = true;
    });

    try {
      // Add main document as the first attachment
      if (widget.data.containsKey('downloadUrl') &&
          widget.data['downloadUrl'] != null &&
          widget.data['downloadUrl'].toString().isNotEmpty) {
        final String url = widget.data['downloadUrl'];
        final String fileName =
            widget.data['fileName'] ?? url.split('/').last.split('?').first;
        final String fileType =
            widget.data['fileType'] ?? fileName.split('.').last.toUpperCase();
        final String fileSize = widget.data['fileSize'] ?? '';
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
            fileSize: fileSize,
            fileType: fileType,
            downloadUrl: url,
            isImage: isImage,
          ),
        );
      }

      // Check for additional attachments array
      if (widget.data.containsKey('attachments') &&
          widget.data['attachments'] is List &&
          (widget.data['attachments'] as List).isNotEmpty) {
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

  Future<void> _openDocument(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: $url'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.data['title'] ?? 'Untitled';
    final String description = widget.data['description'] ?? '';
    final String uploadDate = widget.data['uploadDate'] ?? '';

    // Check if description would overflow
    final bool hasDescription = description.isNotEmpty;
    bool hasTextOverflow = false;

    if (hasDescription) {
      final TextSpan textSpan = TextSpan(
        text: description,
        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
      );

      final TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: _maxLines,
      );

      textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 48);
      hasTextOverflow = textPainter.didExceedMaxLines;
    }

    return Card(
      color: widget.themeColor.withOpacity(0.05),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document title and date row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.insert_drive_file_outlined,
                        color: widget.themeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (uploadDate.isNotEmpty)
                            Text(
                              'Uploaded on: $uploadDate',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Description if available
                if (hasDescription) ...[
                  const SizedBox(height: 16),
                  AnimatedCrossFade(
                    firstChild: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Show Less' : 'Read More',
                            style: TextStyle(
                              color: widget.themeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
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
              ],
            ),
          ),

          // Attachments section
          if (_loadingAttachments)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.themeColor,
                    ),
                  ),
                ),
              ),
            )
          else if (_attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_attachments.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Attachments (${_attachments.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ..._attachments.map(
                    (attachment) => FileAttachmentWidget(
                      attachment: attachment,
                      themeColor: widget.themeColor,
                      showRemoveOption: false,
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Open button
                if (_attachments.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed:
                        () => _openDocument(_attachments.first.downloadUrl!),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
