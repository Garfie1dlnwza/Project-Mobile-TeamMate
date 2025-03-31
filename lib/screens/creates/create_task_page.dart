import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:teammate/services/firestore_noti_service.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/services/file_attachment_service.dart';

import 'package:teammate/widgets/common/file/attachment_picker_widget.dart';
import 'package:teammate/widgets/common/file/file_attachment_widget%20.dart';
import 'package:teammate/widgets/common/file/uploading_attachment_widget.dart';

class CreateTaskPage extends StatefulWidget {
  final String departmentId;
  final String projectId;

  const CreateTaskPage({
    super.key,
    required this.projectId,
    required this.departmentId,
  });

  @override
  _CreateTaskPageState createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirestoreNotificationService _notificationService =
      FirestoreNotificationService();
  // Date and Time
  DateTime? _dueDate;
  bool _isCreating = false;

  // Attachment handling
  final List<FileAttachment> _attachments = [];
  final List<FileAttachment> _uploadingAttachments = [];
  final Map<String, double> _uploadProgress = {};

  void _selectDueDateTime() async {
    // Date selection
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder:
          (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(primary: AppColors.primary),
              buttonTheme: const ButtonThemeData(
                textTheme: ButtonTextTheme.primary,
              ),
            ),
            child: child!,
          ),
    );

    if (pickedDate != null) {
      // Time selection
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder:
            (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(primary: AppColors.primary),
                buttonTheme: const ButtonThemeData(
                  textTheme: ButtonTextTheme.primary,
                ),
              ),
              child: child!,
            ),
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => AttachmentPickerWidget(
            onAttachmentSelected: (attachment) {
              setState(() {
                _attachments.add(attachment);
              });
              Navigator.pop(context);
            },
            themeColor: AppColors.primary,
          ),
    );
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      // Validate due date
      if (_dueDate == null) {
        _showErrorSnackBar('Please select a due date and time');
        return;
      }

      setState(() {
        _isCreating = true;
      });

      try {
        // Get current user
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          _showErrorSnackBar('User not authenticated');
          setState(() {
            _isCreating = false;
          });
          return;
        }

        // Reference to Firestore collections
        final FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Create task document
        DocumentReference taskRef = firestore.collection('tasks').doc();
        final taskId = taskRef.id; // Get the generated task ID

        // Upload attachments if any
        List<Map<String, dynamic>> uploadedAttachments = [];
        final fileAttachmentService = FileAttachmentService();

        for (int i = 0; i < _attachments.length; i++) {
          final attachment = _attachments[i];

          setState(() {
            _uploadingAttachments.add(attachment);
            _uploadProgress[attachment.fileName ?? ''] = 0.0;
          });

          final uploadedAttachment = await fileAttachmentService.uploadFile(
            attachment: attachment,
            storagePath: 'tasks/$taskId/attachments',
            onProgress: (progress) {
              setState(() {
                _uploadProgress[attachment.fileName ?? ''] = progress;
              });
            },
          );

          if (uploadedAttachment != null &&
              uploadedAttachment.downloadUrl != null) {
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

        // Prepare task data
        Map<String, dynamic> taskData = {
          'taskId': taskId,
          'taskTitle': _titleController.text.trim(),
          'taskDescription': _descriptionController.text.trim(),
          'startTask': Timestamp.now(), // Current timestamp as start
          'endTask': Timestamp.fromDate(_dueDate!),
          'creatorId': currentUser.uid,
          'isSubmit': false,
          'isApproved': false,
          'attachments': uploadedAttachments,
          'createdAt': FieldValue.serverTimestamp(),
          'departmentId': widget.departmentId, // Add department ID
        };

        // Save task to Firestore
        await taskRef.set(taskData);

        // Add task ID to department's tasks array
        await firestore
            .collection('departments')
            .doc(widget.departmentId)
            .update({
              'tasks': FieldValue.arrayUnion([taskRef.id]),
            });

        // Show success and vibrate
        HapticFeedback.mediumImpact();
        _showSuccessSnackBar('Task created successfully');
        final departmentDoc =
            await firestore
                .collection('departments')
                .doc(widget.departmentId)
                .get();

        if (departmentDoc.exists) {
          final Map<String, dynamic> departmentData =
              departmentDoc.data() as Map<String, dynamic>;
          final List<dynamic> adminIds = departmentData['admins'] ?? [];
          final List<dynamic> userIds = departmentData['users'] ?? [];

          // Combine both lists and make unique
          final List<String> memberIds =
              [
                ...adminIds,
                ...userIds,
              ].map((id) => id.toString()).toSet().toList();

          // Get creator name
          final String creatorName =
              FirebaseAuth.instance.currentUser?.displayName ?? 'A team member';

          // Send notification to each member except the creator
          for (final memberId in memberIds) {
            if (memberId != currentUser.uid) {
              await _notificationService.sendTaskCreatedNotification(
                userId: memberId,
                taskId: taskId,
                taskTitle: _titleController.text.trim(),
                creatorName: creatorName,
                projectId: widget.projectId,
              );
            }
          }
        }

        // Navigate back with delay for snackbar visibility
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(context).pop(taskRef.id);
        });
      } catch (e) {
        setState(() {
          _isCreating = false;
        });
        _showErrorSnackBar('Error creating task: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'CREATE TASK',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input with gradient border
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryGradientStart,
                          AppColors.primaryGradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(1.5), // Border thickness
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          labelStyle: TextStyle(color: AppColors.labelText),
                          hintText: 'Enter task title',
                          hintStyle: TextStyle(color: AppColors.hintText),
                          prefixIcon: Icon(
                            Icons.title,
                            color: AppColors.secondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a task title';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Input with matching style
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.inputBorder),
                      color: AppColors.background,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: AppColors.labelText),
                        hintText: 'Describe the task details (optional)',
                        hintStyle: TextStyle(color: AppColors.hintText),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 64),
                          child: Icon(
                            Icons.description,
                            color: AppColors.secondary,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Due Date Selection with clean design
                  Text(
                    'Due Date & Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDueDateTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.background,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.inputBorder,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _dueDate == null
                                  ? 'Select a date and time'
                                  : DateFormat(
                                    'EEE, MMM dd, yyyy • HH:mm',
                                  ).format(_dueDate!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    _dueDate == null
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                color:
                                    _dueDate == null
                                        ? AppColors.hintText
                                        : Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.secondary.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Attachments section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attachments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAttachmentPicker,
                        icon: Icon(
                          Icons.attach_file,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          'Add File',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Display selected attachments
                  if (_attachments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_file_outlined,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No attachments added yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAttachmentPicker,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Attachment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              foregroundColor: AppColors.primary,
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
                    )
                  else
                    Column(
                      children: [
                        ...List.generate(_attachments.length, (index) {
                          final attachment = _attachments[index];

                          if (_uploadingAttachments.contains(attachment)) {
                            return UploadingAttachmentWidget(
                              attachment: attachment,
                              progress:
                                  _uploadProgress[attachment.fileName ?? ''] ??
                                  0.0,
                              themeColor: AppColors.primary,
                            );
                          } else {
                            return FileAttachmentWidget(
                              attachment: attachment,
                              themeColor: AppColors.primary,
                              onRemove: () => _removeAttachment(index),
                            );
                          }
                        }),

                        // Add another button
                        if (_attachments.isNotEmpty)
                          TextButton.icon(
                            onPressed: _showAttachmentPicker,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Another File'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: 40),

                  // Create Task Button with gradient
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.buttonColor,
                    ),
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.buttonText,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child:
                          _isCreating
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Creating task...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                              : const Text(
                                'CREATE TASK',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
