import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teammate/services/file_service.dart';

class CreateDocumentPage extends StatefulWidget {
  final String projectId;
  final String departmentId;

  const CreateDocumentPage({
    super.key,
    required this.projectId,
    required this.departmentId,
  });

  @override
  _CreateDocumentPageState createState() => _CreateDocumentPageState();
}

class _CreateDocumentPageState extends State<CreateDocumentPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _attachmentPath;
  Uint8List? _attachmentBytes;
  String? _attachmentName;

  final FileService _fileService = FileService();

  Future<void> _pickAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: kIsWeb, // ดึง bytes ถ้าเป็น Web
    );

    if (result != null) {
      setState(() {
        _attachmentName = result.files.single.name;

        if (kIsWeb) {
          _attachmentBytes = result.files.single.bytes;
        } else {
          _attachmentPath = result.files.single.path;
        }
      });
    }
  }

  Future<void> _createDocument() async {
    if (_titleController.text.isEmpty ||
        (_attachmentPath == null && _attachmentBytes == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('กรุณากรอกชื่อเอกสารและแนบไฟล์')));
      return;
    }

    try {
      String documentId = await _fileService.createDocument(
        projectId: widget.projectId,
        departmentId: widget.departmentId,
        title: _titleController.text,
        description: _descriptionController.text,
        attachmentPath: _attachmentPath,
        attachmentBytes: _attachmentBytes,
        attachmentName: _attachmentName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สร้างเอกสารสำเร็จ ID: $documentId')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Create Document',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Document Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickAttachment,
              child: Text(
                _attachmentName == null
                    ? 'Add Attachment'
                    : 'Attachment: $_attachmentName',
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createDocument,
              child: Text(
                'Create Document',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
