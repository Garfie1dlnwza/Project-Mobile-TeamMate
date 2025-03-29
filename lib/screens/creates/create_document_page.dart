import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teammate/services/googledrive_file.dart';
import 'package:teammate/theme/app_colors.dart';

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
  String? _attachmentSize;
  String? _attachmentType;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final GoogleDriveFileService _fileService = GoogleDriveFileService();

  Future<void> _pickAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null) {
        final file = result.files.single;

        // คำนวณขนาดไฟล์ในหน่วยที่เหมาะสม
        String fileSize;
        int bytes = file.size;

        if (bytes < 1024) {
          fileSize = '$bytes B';
        } else if (bytes < 1024 * 1024) {
          fileSize = '${(bytes / 1024).toStringAsFixed(1)} KB';
        } else if (bytes < 1024 * 1024 * 1024) {
          fileSize = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        } else {
          fileSize = '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
        }

        setState(() {
          _attachmentName = file.name;
          _attachmentSize = fileSize;
          _attachmentType = file.extension?.toUpperCase() ?? 'UNKNOWN';

          if (kIsWeb) {
            _attachmentBytes = file.bytes;
          } else {
            _attachmentPath = file.path;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting file: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _createDocument() async {
    if (_titleController.text.isEmpty) {
      _showErrorSnackBar('กรุณากรอกชื่อเอกสาร');
      return;
    }

    if (_attachmentPath == null && _attachmentBytes == null) {
      _showErrorSnackBar('กรุณาแนบไฟล์');
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      _simulateUploadProgress();

      String documentId = await _fileService.createDocument(
        projectId: widget.projectId,
        departmentId: widget.departmentId,
        title: _titleController.text,
        description: _descriptionController.text,
        attachmentPath: _attachmentPath,
        attachmentBytes: _attachmentBytes,
        attachmentName: _attachmentName,
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      _showSuccessSnackBar('สร้างเอกสารสำเร็จ!');
      Navigator.pop(context, documentId);
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (!mounted) return;
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _simulateUploadProgress() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isUploading && mounted) {
        setState(() {
          _uploadProgress = 0.15;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isUploading && mounted) {
            setState(() {
              _uploadProgress = 0.45;
            });

            Future.delayed(const Duration(milliseconds: 800), () {
              if (_isUploading && mounted) {
                setState(() {
                  _uploadProgress = 0.75;
                });
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        title: const Text(
          'Create Document',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background design
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page description
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 22,
                    ),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.insert_drive_file_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share a Document',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Upload a file to share with your team members',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document title
                        const Row(
                          children: [
                            Icon(
                              Icons.title,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Document Title',
                              style: TextStyle(
                                color: AppColors.labelText,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Enter document title',
                            hintStyle: const TextStyle(
                              color: AppColors.hintText,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description
                        const Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Description',
                              style: TextStyle(
                                color: AppColors.labelText,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Enter document description (optional)',
                            hintStyle: const TextStyle(
                              color: AppColors.hintText,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Attachment section
                        const Row(
                          children: [
                            Icon(
                              Icons.attach_file_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Attachment',
                              style: TextStyle(
                                color: AppColors.labelText,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // File upload area
                        if (_attachmentName == null)
                          GestureDetector(
                            onTap: _pickAttachment,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.07,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 32,
                                      color: AppColors.primary.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Drag and drop your file here',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'or ',
                                        style: TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'browse files',
                                        style: TextStyle(
                                          color: AppColors.primary.withOpacity(
                                            0.8,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Supported formats: PDF, Word, Excel, PowerPoint, Images',
                                    style: TextStyle(
                                      color: AppColors.secondary.withOpacity(
                                        0.8,
                                      ),
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // Selected file preview
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // File icon
                                    _buildFileIcon(),
                                    const SizedBox(width: 16),
                                    // File info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _attachmentName!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.07),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '$_attachmentType • $_attachmentSize',
                                              style: TextStyle(
                                                color: AppColors.primary
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Remove button
                                    IconButton(
                                      onPressed:
                                          () => setState(() {
                                            _attachmentName = null;
                                            _attachmentPath = null;
                                            _attachmentBytes = null;
                                            _attachmentSize = null;
                                            _attachmentType = null;
                                          }),
                                      icon: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red[400],
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Change file button
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey[200],
                                  margin: const EdgeInsets.only(bottom: 16),
                                ),
                                InkWell(
                                  onTap: _pickAttachment,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.file_upload_outlined,
                                          size: 18,
                                          color: AppColors.primary.withOpacity(
                                            0.8,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Change File',
                                          style: TextStyle(
                                            color: AppColors.primary
                                                .withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Upload button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      foregroundColor: AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _attachmentName == null
                              ? Icons.cloud_upload_outlined
                              : Icons.check_circle_outline,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Upload Document',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: BackdropFilter(
                filter:
                    kIsWeb
                        ? ImageFilter.blur(sigmaX: 5, sigmaY: 5)
                        : ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Uploading Document',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 250,
                            child: Text(
                              'Please wait while we upload your document to Google Drive...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_isUploading) ...[
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileIcon() {
    Color iconColor;
    IconData iconData;

    if (_attachmentType == null) {
      iconColor = Colors.grey;
      iconData = Icons.insert_drive_file;
    } else {
      final type = _attachmentType!.toLowerCase();

      if (type == 'pdf') {
        iconColor = Colors.red[600]!;
        iconData = Icons.picture_as_pdf;
      } else if (['doc', 'docx'].contains(type)) {
        iconColor = Colors.blue[600]!;
        iconData = Icons.description;
      } else if (['xls', 'xlsx', 'csv'].contains(type)) {
        iconColor = Colors.green[600]!;
        iconData = Icons.table_chart;
      } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(type)) {
        iconColor = Colors.purple[600]!;
        iconData = Icons.image;
      } else if (['ppt', 'pptx'].contains(type)) {
        iconColor = Colors.orange[600]!;
        iconData = Icons.slideshow;
      } else if (['zip', 'rar', '7z'].contains(type)) {
        iconColor = Colors.amber[600]!;
        iconData = Icons.folder_zip;
      } else {
        iconColor = Colors.blueGrey[600]!;
        iconData = Icons.insert_drive_file;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 28),
    );
  }
}
