import 'package:flutter/material.dart';
import 'package:teammate/services/file_attachment_service.dart';

class UploadingAttachmentWidget extends StatelessWidget {
  final FileAttachment attachment;
  final double progress;
  final VoidCallback? onCancel;
  final Color themeColor;

  const UploadingAttachmentWidget({
    super.key,
    required this.attachment,
    required this.progress,
    this.onCancel,
    this.themeColor = const Color(0xFF424242), // Default to Colors.grey[800]
  });

  @override
  Widget build(BuildContext context) {
    final fileAttachmentService = FileAttachmentService();
    final IconData fileIcon = fileAttachmentService.getFileIcon(
      attachment.fileType?.toLowerCase() ?? '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // ปุ่มยกเลิก
              if (onCancel != null)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red.shade400),
                  onPressed: onCancel,
                ),
            ],
          ),

          // Progress bar
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
