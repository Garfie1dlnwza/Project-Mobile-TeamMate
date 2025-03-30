import 'package:flutter/material.dart';
import 'package:teammate/services/file_attachment_service.dart';

class AttachmentPickerWidget extends StatelessWidget {
  final Function(FileAttachment) onAttachmentSelected;
  final Color themeColor;

  const AttachmentPickerWidget({
    Key? key,
    required this.onAttachmentSelected,
    this.themeColor = const Color(0xFF424242), // Default to Colors.grey[800]
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            context: context,
            icon: Icons.photo_library_outlined,
            label: 'รูปภาพ',
            color: Colors.green.shade600,
            onTap: () => _pickImage(context),
          ),
          _buildAttachmentOption(
            context: context,
            icon: Icons.attach_file_outlined,
            label: 'ไฟล์',
            color: Colors.orange.shade600,
            onTap: () => _pickFile(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final fileAttachmentService = FileAttachmentService();
    final FileAttachment? attachment = await fileAttachmentService.pickImage();

    if (attachment != null) {
      onAttachmentSelected(attachment);
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    final fileAttachmentService = FileAttachmentService();
    final FileAttachment? attachment = await fileAttachmentService.pickFile();

    if (attachment != null) {
      onAttachmentSelected(attachment);
    }
  }
}
