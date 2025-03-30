import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:teammate/services/file_attachment_service.dart';

class FileAttachmentWidget extends StatelessWidget {
  final FileAttachment attachment;
  final VoidCallback? onRemove;
  final bool showRemoveOption;
  final Color themeColor;

  const FileAttachmentWidget({
    Key? key,
    required this.attachment,
    this.onRemove,
    this.showRemoveOption = true,
    this.themeColor = const Color(0xFF424242), // Default to Colors.grey[800]
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) {
      return _buildImagePreview(context);
    } else {
      return _buildFilePreview(context);
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    Widget imageWidget;

    if (attachment.downloadUrl != null) {
      // หากมี URL ดาวน์โหลด ให้แสดงรูปจาก URL
      imageWidget = Image.network(
        attachment.downloadUrl!,
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, color: Colors.grey[600], size: 48),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                color: themeColor,
              ),
            ),
          );
        },
      );
    } else if (attachment.fileBytes != null) {
      // สำหรับ web
      imageWidget = Image.memory(
        attachment.fileBytes!,
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
      );
    } else if (attachment.localPath != null) {
      // สำหรับ mobile
      imageWidget = Image.file(
        File(attachment.localPath!),
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
      );
    } else {
      // กรณีไม่มีรูปภาพ
      return const SizedBox();
    }

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
        ),
        if (showRemoveOption && onRemove != null)
          Positioned(
            right: 8,
            top: 8,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilePreview(BuildContext context) {
    final fileAttachmentService = FileAttachmentService();
    final IconData fileIcon = fileAttachmentService.getFileIcon(
      attachment.fileType?.toLowerCase() ?? '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // ไอคอนตามประเภทไฟล์
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(fileIcon, color: Colors.blue.shade700, size: 24),
          ),

          const SizedBox(width: 12),

          // ข้อมูลไฟล์
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName ?? 'ไฟล์',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${attachment.fileType ?? ''} · ${attachment.fileSize ?? ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // ปุ่มดาวน์โหลด/เปิดไฟล์
          if (attachment.downloadUrl != null)
            IconButton(
              icon: Icon(Icons.open_in_new, color: themeColor),
              onPressed: () => _openFile(context, attachment.downloadUrl!),
            ),

          // ปุ่มลบไฟล์
          if (showRemoveOption && onRemove != null)
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade400),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่สามารถเปิดไฟล์ได้: $url')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }
}
