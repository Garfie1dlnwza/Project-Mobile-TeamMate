import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/services/firestore_noti_service.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/services/file_attachment_service.dart';
import 'package:teammate/widgets/common/file/file_attachment_widget%20.dart';
import 'package:teammate/widgets/common/file/uploading_attachment_widget.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

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
  final FirestoreNotificationService _notificationService =
      FirestoreNotificationService();

  // For attachments
  final List<FileAttachment> _attachments = [];
  final List<FileAttachment> _uploadingAttachments = [];
  final Map<String, double> _uploadProgress = {};

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isDragging = false;

  late DropzoneViewController _dropzoneController;

  // Firebase instances
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FileAttachmentService _fileAttachmentService = FileAttachmentService();

  void _handleAddAttachment(FileAttachment attachment) {
    setState(() {
      _attachments.add(attachment);
    });
  }

  void _removeAttachment(FileAttachment attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
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

  Future<void> _handleFileDrop(dynamic event) async {
    setState(() {
      _isDragging = false;
    });

    if (!kIsWeb) return; // Only process for web platform

    try {
      final name = await _dropzoneController.getFilename(event);
      final mime = await _dropzoneController.getFileMIME(event);
      final size = await _dropzoneController.getFileSize(event);
      final fileBytes = await _dropzoneController.getFileData(event);

      // Determine file type from MIME or fallback to extension
      String fileType = mime.split('/').last.toUpperCase();
      if (name.contains('.')) {
        final extension = name.split('.').last.toUpperCase();
        if (extension.isNotEmpty) {
          fileType = extension;
        }
      }

      // Calculate file size string
      String fileSize;
      if (size < 1024) {
        fileSize = '$size B';
      } else if (size < 1024 * 1024) {
        fileSize = '${(size / 1024).toStringAsFixed(1)} KB';
      } else if (size < 1024 * 1024 * 1024) {
        fileSize = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        fileSize = '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
      }

      // Check if it's an image
      bool isImage =
          ['JPG', 'JPEG', 'PNG', 'GIF', 'WEBP', 'BMP'].contains(fileType) ||
          mime.startsWith('image/');

      // Create FileAttachment object
      final attachment = FileAttachment(
        fileName: name,
        fileType: fileType,
        fileSize: fileSize,
        fileBytes: fileBytes,
        isImage: isImage,
      );

      setState(() {
        _attachments.add(attachment);
      });
    } catch (e) {
      _showErrorSnackBar('Error processing dropped file: $e');
    }
  }

  Future<void> _selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          // Calculate file size string
          String fileSize;
          int bytes = file.size;

          if (bytes < 1024) {
            fileSize = '$bytes B';
          } else if (bytes < 1024 * 1024) {
            fileSize = '${(bytes / 1024).toStringAsFixed(1)} KB';
          } else if (bytes < 1024 * 1024 * 1024) {
            fileSize = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
          } else {
            fileSize =
                '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
          }

          String fileType = file.extension?.toUpperCase() ?? 'UNKNOWN';
          bool isImage = [
            'JPG',
            'JPEG',
            'PNG',
            'GIF',
            'WEBP',
            'BMP',
          ].contains(fileType);

          Uint8List? fileBytes;
          String? localPath;

          if (kIsWeb) {
            fileBytes = file.bytes;
          } else {
            localPath = file.path;
          }

          final attachment = FileAttachment(
            fileName: file.name,
            fileType: fileType,
            fileSize: fileSize,
            fileBytes: fileBytes,
            localPath: localPath,
            isImage: isImage,
          );

          setState(() {
            _attachments.add(attachment);
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting files: $e');
    }
  }
  // Completely replace the original _createDocument method with this:

  Future<void> _createDocument() async {
    if (_titleController.text.isEmpty) {
      _showErrorSnackBar('Please enter a document title');
      return;
    }

    if (_attachments.isEmpty) {
      _showErrorSnackBar('Please attach at least one file');
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      // Create a new document reference in top-level collection (similar to tasks)
      DocumentReference docRef = _firestore.collection('documents').doc();
      final String documentId = docRef.id;

      // Upload all attachments
      List<Map<String, dynamic>> uploadedAttachments = [];
      String mainDocumentUrl = '';

      for (var attachment in _attachments) {
        setState(() {
          _uploadingAttachments.add(attachment);
          _uploadProgress[attachment.fileName ?? ''] = 0.0;
        });

        final uploadedAttachment = await _fileAttachmentService.uploadFile(
          attachment: attachment,
          storagePath: 'documents/$documentId', // Simplified storage path
          onProgress: (progress) {
            setState(() {
              _uploadProgress[attachment.fileName ?? ''] = progress;
            });
          },
        );

        if (uploadedAttachment != null &&
            uploadedAttachment.downloadUrl != null) {
          // For the first attachment, set it as the main document URL
          if (mainDocumentUrl.isEmpty) {
            mainDocumentUrl = uploadedAttachment.downloadUrl!;
          }

          // Add to attachments array
          uploadedAttachments.add({
            'fileName': uploadedAttachment.fileName,
            'fileSize': uploadedAttachment.fileSize,
            'fileType': uploadedAttachment.fileType,
            'downloadUrl': uploadedAttachment.downloadUrl,
            'isImage': uploadedAttachment.isImage,
          });
        }

        setState(() {
          _uploadingAttachments.remove(attachment);
        });
      }

      // Create document data
      Map<String, dynamic> documentData = {
        'documentId': documentId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'departmentId': widget.departmentId,
        'projectId': widget.projectId,
        'uploadedBy': FirebaseAuth.instance.currentUser?.uid,
        'uploadedByName': FirebaseAuth.instance.currentUser?.displayName,
        'attachments': uploadedAttachments,
      };

      // If we have at least one attachment, add main document info for backward compatibility
      if (uploadedAttachments.isNotEmpty) {
        final mainAttachment = uploadedAttachments.first;
        documentData.addAll({
          'fileName': mainAttachment['fileName'],
          'fileType': mainAttachment['fileType'],
          'fileSize': mainAttachment['fileSize'],
          'downloadUrl': mainAttachment['downloadUrl'],
        });
      }

      // Save document to Firestore
      await docRef.set(documentData);

      // Create a feed item for this document
      await _firestore
          .collection('projects')
          .doc(widget.projectId)
          .collection('feed')
          .add({
            'type': 'document',
            'createdAt': FieldValue.serverTimestamp(),
            'departmentId': widget.departmentId,
            'projectId': widget.projectId,
            'documentId': documentId, // Add document ID reference
            'data': documentData,
          });

      // Add document ID to department's documents array
      await _firestore
          .collection('departments')
          .doc(widget.departmentId)
          .update({
            'documents': FieldValue.arrayUnion([docRef.id]),
          });

      setState(() {
        _isUploading = false;
        _isLoading = false;
      });

      final departmentDoc =
          await _firestore
              .collection('departments')
              .doc(widget.departmentId)
              .get();

      if (departmentDoc.exists) {
        // Send notification to all department members
        await _notificationService.sendNotificationToDepartmentMembers(
          departmentId: widget.departmentId,
          type: 'document_shared',
          message:
              '${FirebaseAuth.instance.currentUser?.displayName ?? 'A team member'} shared a new document: ${_titleController.text}',
          additionalData: {
            'documentId': docRef.id,
            'documentTitle': _titleController.text,
            'sharerName':
                FirebaseAuth.instance.currentUser?.displayName ??
                'A team member',
            'projectId': widget.projectId,
          },
        );
      }

      _showSuccessSnackBar('Document created successfully!');
      await _notificationService.sendDocumentSharedNotification(
        departmentId: widget.departmentId,
        documentId: docRef.id,
        documentTitle: _titleController.text,
        sharerName:
            FirebaseAuth.instance.currentUser?.displayName ?? 'A team member',
        projectId: widget.projectId,
      );

      Navigator.pop(context, docRef.id);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isLoading = false;
      });

      if (!mounted) return;
      _showErrorSnackBar('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        // foregroundColor: AppColors.primary,
        title: const Text(
          'CREATE DOCUMENT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
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
                                'Upload files to share with your team members',
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

                        // Attachments section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.attach_file_outlined,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Attachments',
                                  style: TextStyle(
                                    color: AppColors.labelText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _selectFiles,
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              label: const Text(
                                'Add Files',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Display selected attachments or drop zone
                        if (_attachments.isEmpty)
                          // Drop zone for files
                          kIsWeb
                              ? Stack(
                                children: [
                                  // Dropzone
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color:
                                          _isDragging
                                              ? AppColors.primary.withOpacity(
                                                0.1,
                                              )
                                              : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            _isDragging
                                                ? AppColors.primary
                                                : Colors.grey[200]!,
                                        width: _isDragging ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        DropzoneView(
                                          onCreated:
                                              (controller) =>
                                                  _dropzoneController =
                                                      controller,
                                          onDrop: _handleFileDrop,
                                          onHover:
                                              () => setState(
                                                () => _isDragging = true,
                                              ),
                                          onLeave:
                                              () => setState(
                                                () => _isDragging = false,
                                              ),
                                        ),
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _isDragging
                                                    ? Icons.file_download
                                                    : Icons.upload_file,
                                                size: 48,
                                                color:
                                                    _isDragging
                                                        ? AppColors.primary
                                                        : Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                _isDragging
                                                    ? 'Drop files here to upload'
                                                    : 'Drag and drop your files here',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      _isDragging
                                                          ? AppColors.primary
                                                          : Colors.grey[700],
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'or ',
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: _selectFiles,
                                                    child: Text(
                                                      'browse files',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Supported formats: PDF, Word, Excel, PowerPoint, Images',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                              : GestureDetector(
                                onTap: _selectFiles,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tap to select files',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Supported formats: PDF, Word, Excel, PowerPoint, Images',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                        else
                          Column(
                            children: [
                              ...List.generate(_attachments.length, (index) {
                                final attachment = _attachments[index];

                                if (_uploadingAttachments.contains(
                                  attachment,
                                )) {
                                  return UploadingAttachmentWidget(
                                    attachment: attachment,
                                    progress:
                                        _uploadProgress[attachment.fileName ??
                                            ''] ??
                                        0.0,
                                    themeColor: AppColors.primary,
                                    onCancel:
                                        () => _removeAttachment(attachment),
                                  );
                                } else {
                                  return FileAttachmentWidget(
                                    attachment: attachment,
                                    themeColor: AppColors.primary,
                                    onRemove:
                                        () => _removeAttachment(attachment),
                                  );
                                }
                              }),

                              // Add another button
                              TextButton.icon(
                                onPressed: _selectFiles,
                                icon: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                label: const Text('Add More Files'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
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
                          _attachments.isEmpty
                              ? Icons.cloud_upload_outlined
                              : Icons.check_circle_outline,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _attachments.isEmpty
                              ? 'Select Files'
                              : 'Upload Document',
                          style: const TextStyle(
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
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                              'Please wait while we upload your files to Firebase Storage...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (_uploadingAttachments.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Uploading: ${_uploadingAttachments.first.fileName ?? "File"}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value:
                                  _uploadProgress[_uploadingAttachments
                                          .first
                                          .fileName ??
                                      ''] ??
                                  0,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${((_uploadProgress[_uploadingAttachments.first.fileName ?? ''] ?? 0) * 100).toInt()}%',
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
}
