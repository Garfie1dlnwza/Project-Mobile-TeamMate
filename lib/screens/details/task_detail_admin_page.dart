import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/utils/date.dart';
import 'package:teammate/services/file_attachment_service.dart';
import 'package:teammate/widgets/common/file/attachment_picker_widget.dart';
import 'package:teammate/widgets/common/file/file_attachment_widget%20.dart';
import 'package:teammate/widgets/common/file/uploading_attachment_widget.dart';

class TaskDetailsAdminPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color themeColor;
  final bool isAdminOrHead;

  const TaskDetailsAdminPage({
    Key? key,
    required this.data,
    required this.themeColor,
    required this.isAdminOrHead,
  }) : super(key: key);

  @override
  State<TaskDetailsAdminPage> createState() => _TaskDetailsAdminPageState();
}

class _TaskDetailsAdminPageState extends State<TaskDetailsAdminPage> {
  bool isLoading = false;
  Map<String, dynamic>? submissionData;
  String? submittingUserName;
  String? submittingUserEmail;

  // For file attachments
  List<FileAttachment> _attachments = [];
  bool _loadingAttachments = false;

  // For new attachment uploads
  List<FileAttachment> _pendingAttachments = [];
  List<FileAttachment> _uploadingAttachments = [];
  Map<String, double> _uploadProgress = {};
  bool _canAddAttachments = false;

  @override
  void initState() {
    super.initState();
    _loadAttachments();

    if (widget.isAdminOrHead && widget.data['isSubmit'] == true) {
      _loadSubmissionData();
    }

    // Define if user can add attachments (based on task status and user role)
    _canAddAttachments =
        widget.isAdminOrHead ||
        !(widget.data['isSubmit'] ?? false) ||
        (widget.data['isRejected'] ?? false);
  }

  Future<void> _loadAttachments() async {
    if (widget.data['attachments'] == null ||
        (widget.data['attachments'] is List &&
            (widget.data['attachments'] as List).isEmpty)) {
      return;
    }

    setState(() {
      _loadingAttachments = true;
    });

    try {
      List<dynamic> attachmentsData = widget.data['attachments'] as List;
      List<FileAttachment> loadedAttachments = [];

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

          loadedAttachments.add(
            FileAttachment(
              fileName: fileName,
              fileType: fileType,
              downloadUrl: url,
              isImage: isImage,
            ),
          );
        } else if (item is Map<String, dynamic>) {
          // New format: Map with details
          loadedAttachments.add(
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

      setState(() {
        _attachments = loadedAttachments;
      });
    } catch (e) {
      print('Error loading attachments: $e');
    } finally {
      setState(() {
        _loadingAttachments = false;
      });
    }
  }

  Future<void> _loadSubmissionData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final taskId = widget.data['taskId'];
      final userId = widget.data['submittedBy'];

      if (userId != null) {
        // Get submission data
        final submissionSnapshot =
            await FirebaseFirestore.instance
                .collection('tasks')
                .doc(taskId)
                .collection('submissions')
                .where('userId', isEqualTo: userId)
                .limit(1)
                .get();

        if (submissionSnapshot.docs.isNotEmpty) {
          setState(() {
            submissionData = submissionSnapshot.docs.first.data();
            submissionData!['id'] = submissionSnapshot.docs.first.id;
          });
        }

        // Get user data
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            submittingUserName = userData['name'] ?? 'Unknown User';
            submittingUserEmail = userData['email'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading submission data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitTask() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to submit tasks')),
        );
        return;
      }

      final taskId = widget.data['taskId'];
      print("✅ Task ID: $taskId");

      // Upload pending attachments first
      List<Map<String, dynamic>> uploadedAttachments = [];

      // First add existing attachments
      for (var attachment in _attachments) {
        if (attachment.downloadUrl != null) {
          uploadedAttachments.add({
            'fileName': attachment.fileName,
            'fileSize': attachment.fileSize,
            'fileType': attachment.fileType,
            'downloadUrl': attachment.downloadUrl,
            'isImage': attachment.isImage,
          });
        }
      }

      // Then upload and add new attachments
      for (var attachment in _pendingAttachments) {
        setState(() {
          _uploadingAttachments.add(attachment);
          _uploadProgress[attachment.fileName ?? ''] = 0.0;
        });

        final fileAttachmentService = FileAttachmentService();
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

      // Check if user already submitted and task wasn't rejected
      final existingSubmissions =
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .collection('submissions')
              .where('userId', isEqualTo: currentUser.uid)
              .limit(1)
              .get();

      if (existingSubmissions.docs.isNotEmpty &&
          !(widget.data['isRejected'] ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This task has already been submitted.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create a submission
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .collection('submissions')
          .add({
            'userId': currentUser.uid,
            'submittedAt': Timestamp.now(),
            'status': 'pending',
          });

      // Update task as submitted but not yet approved, and clear rejection status if exists
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'isSubmit': true,
        'isRejected': false, // Clear rejection status
        'submittedBy': currentUser.uid,
        'submittedAt': Timestamp.now(),
        'isApproved': false,
        'attachments': uploadedAttachments,
      });

      setState(() {
        _pendingAttachments = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task submitted for review'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh page
      Navigator.pop(context);
    } catch (e) {
      print('Error submitting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleReviewAction(String action) async {
    setState(() {
      isLoading = true;
    });

    try {
      final taskId = widget.data['taskId'];
      final submissionId = submissionData?['id'];

      if (submissionId == null) {
        throw Exception('Submission data not found');
      }

      // Update submission status
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .collection('submissions')
          .doc(submissionId)
          .update({
            'status': action,
            'reviewedAt': Timestamp.now(),
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
          });

      // Update main task document
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'isApproved': action == 'accepted',
        'isRejected': action == 'rejected',
        'isSubmit': action == 'accepted', // Only keep as submitted if accepted
        'reviewedAt': Timestamp.now(),
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task ${action == 'accepted' ? 'accepted' : 'rejected'} successfully',
          ),
          backgroundColor: action == 'accepted' ? Colors.green : Colors.red,
        ),
      );

      // Refresh page
      Navigator.pop(context);
    } catch (e) {
      print('Error reviewing submission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleAddAttachment(FileAttachment attachment) {
    setState(() {
      _pendingAttachments.add(attachment);
    });
  }

  void _removePendingAttachment(FileAttachment attachment) {
    setState(() {
      _pendingAttachments.remove(attachment);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.data['taskTitle'] ?? 'Untitled Task';
    final String description =
        widget.data['taskDescription'] ?? 'No description provided';
    final bool isSubmitted = widget.data['isSubmit'] ?? false;
    final bool isApproved = widget.data['isApproved'] ?? false;
    final bool isRejected = widget.data['isRejected'] ?? false;
    final Timestamp endDate = widget.data['endTask'] ?? Timestamp.now();
    final DateTime dueDate = endDate.toDate();
    final bool isOverdue =
        DateTime.now().isAfter(dueDate) && !isApproved && !isSubmitted;
    final Duration timeLeft = dueDate.difference(DateTime.now());
    final bool isUrgent =
        timeLeft.inDays <= 2 && !isApproved && !isSubmitted && !isRejected;

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details'), elevation: 0),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and due date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              isApproved,
                              isSubmitted,
                              isRejected,
                              isOverdue,
                              isUrgent,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getStatusText(
                              isApproved,
                              isSubmitted,
                              isRejected,
                              isOverdue,
                              isUrgent,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color:
                                    isOverdue
                                        ? Colors.red[600]
                                        : Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormatter.formatDateShort(dueDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isOverdue
                                          ? Colors.red[600]
                                          : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Title',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Attachments section
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attachments',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_canAddAttachments)
                          TextButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder:
                                    (context) => AttachmentPickerWidget(
                                      onAttachmentSelected:
                                          _handleAddAttachment,
                                      themeColor: widget.themeColor,
                                    ),
                              );
                            },
                            icon: Icon(
                              Icons.attach_file,
                              size: 18,
                              color: widget.themeColor,
                            ),
                            label: Text(
                              'Add',
                              style: TextStyle(
                                color: widget.themeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Show loading indicator while loading attachments
                    if (_loadingAttachments)
                      Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.themeColor,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    // Show message if no attachments
                    else if (_attachments.isEmpty &&
                        _pendingAttachments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.attach_file_outlined,
                              size: 36,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No attachments for this task',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (_canAddAttachments) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder:
                                        (context) => AttachmentPickerWidget(
                                          onAttachmentSelected:
                                              _handleAddAttachment,
                                          themeColor: widget.themeColor,
                                        ),
                                  );
                                },
                                icon: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: widget.themeColor,
                                ),
                                label: const Text('Add Attachment'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: widget.themeColor,
                                  side: BorderSide(color: widget.themeColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    // Show attachments
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Existing attachments
                          ..._attachments.map(
                            (attachment) => FileAttachmentWidget(
                              attachment: attachment,
                              themeColor: widget.themeColor,
                              showRemoveOption: false,
                            ),
                          ),

                          // Pending attachments
                          ..._pendingAttachments.map(
                            (attachment) =>
                                _uploadingAttachments.contains(attachment)
                                    ? UploadingAttachmentWidget(
                                      attachment: attachment,
                                      progress:
                                          _uploadProgress[attachment.fileName ??
                                              ''] ??
                                          0.0,
                                      themeColor: widget.themeColor,
                                    )
                                    : FileAttachmentWidget(
                                      attachment: attachment,
                                      themeColor: widget.themeColor,
                                      onRemove:
                                          () => _removePendingAttachment(
                                            attachment,
                                          ),
                                    ),
                          ),
                        ],
                      ),

                    // Submission info for admin/head
                    if (widget.isAdminOrHead && isSubmitted) ...[
                      const SizedBox(height: 24),

                      Text(
                        'Submission Information',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submitted by: ${submittingUserName ?? 'Unknown User'}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (submittingUserEmail != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Email: $submittingUserEmail',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Submitted on: ${submissionData != null && submissionData!.containsKey('submittedAt') && submissionData!['submittedAt'] is Timestamp ? DateFormatter.formatDateTime((submissionData!['submittedAt'] as Timestamp).toDate()) : 'Unknown date'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status: ${submissionData != null ? (submissionData!['status'] ?? 'pending').toUpperCase() : 'PENDING'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _getSubmissionStatusColor(
                                  submissionData != null
                                      ? (submissionData!['status'] ?? 'pending')
                                      : 'pending',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Action buttons
                    if (!widget.isAdminOrHead) ...[
                      if (isRejected)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitTask,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Resubmit Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.themeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        )
                      else if (isApproved)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        )
                      else if (isSubmitted)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.hourglass_empty, size: 18),
                            label: const Text('Pending Approval'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitTask,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Submit Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.themeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                    ],

                    if (widget.isAdminOrHead &&
                        isSubmitted &&
                        !(widget.data['isApproved'] ?? false))
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleReviewAction('rejected'),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleReviewAction('accepted'),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
    );
  }

  Color _getStatusColor(
    bool isApproved,
    bool isSubmitted,
    bool isRejected,
    bool isOverdue,
    bool isUrgent,
  ) {
    if (isApproved) return Colors.green[600]!;
    if (isRejected) return Colors.red[600]!;
    if (isSubmitted) return Colors.blue[600]!;
    if (isOverdue) return Colors.red[600]!;
    if (isUrgent) return Colors.orange[600]!;
    return Colors.grey[700]!;
  }

  String _getStatusText(
    bool isApproved,
    bool isSubmitted,
    bool isRejected,
    bool isOverdue,
    bool isUrgent,
  ) {
    if (isApproved) return 'APPROVED';
    if (isRejected) return 'REJECTED';
    if (isSubmitted) return 'SUBMITTED';
    if (isOverdue) return 'OVERDUE';
    if (isUrgent) return 'URGENT';
    return 'NORMAL';
  }

  Color _getSubmissionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green[600]!;
      case 'rejected':
        return Colors.red[600]!;
      case 'pending':
      default:
        return Colors.orange[600]!;
    }
  }
}
