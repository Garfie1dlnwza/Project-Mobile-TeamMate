import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:teammate/services/firestore_noti_service.dart';
import 'package:teammate/services/firestore_post.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/services/file_attachment_service.dart';
import 'package:teammate/widgets/common/file/attachment_picker_widget.dart';
import 'package:teammate/widgets/common/file/file_attachment_widget%20.dart';
import 'package:teammate/widgets/common/file/uploading_attachment_widget.dart';

class CreatePost extends StatefulWidget {
  final String departmentId;
  const CreatePost({super.key, required this.departmentId});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  final FirestorePostService _postService = FirestorePostService();
  final User? user = FirebaseAuth.instance.currentUser;
  final FirestoreNotificationService _notificationService =
      FirestoreNotificationService();

  bool _isSubmitting = false;

  // For file attachments
  List<FileAttachment> _attachments = [];
  List<FileAttachment> _uploadingAttachments = [];
  Map<String, double> _uploadProgress = {};

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _formAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Form fade-in animation
    _formAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Button scale animation
    _buttonAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    );

    // Slide animation for attachment options
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start the animation after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _postController.dispose();
    _animationController.dispose();
    super.dispose();
  }

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

  // Handle post submission
  Future<void> _handlePostSubmission() async {
    final title = _titleController.text.trim();
    final postText = _postController.text.trim();

    if (title.isEmpty || postText.isEmpty) {
      _showErrorSnackBar(
        title.isEmpty
            ? 'Please enter a post title'
            : 'Please enter post content',
      );
      // Add shake animation for error
      _animateError();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload attachments
      List<Map<String, dynamic>> uploadedAttachments = [];
      String? imageUrl;
      String? fileUrl;

      final fileAttachmentService = FileAttachmentService();

      for (var attachment in _attachments) {
        setState(() {
          _uploadingAttachments.add(attachment);
          _uploadProgress[attachment.fileName ?? ''] = 0.0;
        });

        final uploadedAttachment = await fileAttachmentService.uploadFile(
          attachment: attachment,
          storagePath: 'posts/${user?.uid}',
          onProgress: (progress) {
            setState(() {
              _uploadProgress[attachment.fileName ?? ''] = progress;
            });
          },
        );

        if (uploadedAttachment != null &&
            uploadedAttachment.downloadUrl != null) {
          // For backward compatibility, set the first image to imageUrl and first file to fileUrl
          if (uploadedAttachment.isImage && imageUrl == null) {
            imageUrl = uploadedAttachment.downloadUrl;
          } else if (!uploadedAttachment.isImage && fileUrl == null) {
            fileUrl = uploadedAttachment.downloadUrl;
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

      // Create post with attachments
      await _postService.createPost(
        creatorId: user!.uid,
        title: title,
        description: postText,
        departmentId: widget.departmentId,
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        attachments: uploadedAttachments,
      );

      _titleController.clear();
      _postController.clear();

      if (mounted) {
        // Show success animation before navigating back
        _animateSuccess(() {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        });
        final departmentDoc =
            await FirebaseFirestore.instance
                .collection('departments')
                .doc(widget.departmentId)
                .get();

        if (departmentDoc.exists) {
          final deptData = departmentDoc.data() as Map<String, dynamic>;
          final String projectId = deptData['projectId'] ?? '';
          final String postId =
              FirebaseFirestore.instance.collection('posts').doc().id;
          // Send notification to all department members
          await _notificationService.sendNotificationToDepartmentMembers(
            departmentId: widget.departmentId,
            type: 'post_created',
            message:
                '${user?.displayName ?? 'A team member'} created a new post: ${_titleController.text}',
            additionalData: {
              'postId':
                  postId, // Assuming you have this from the returned document ID
              'postTitle': _titleController.text,
              'creatorName': user?.displayName ?? 'A team member',
              'projectId': projectId,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Could not create post: $e');
        _animateError();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _animateError() {
    // Create a shake animation for error
    final shakeCount = 4;
    final shakeOffset = 10.0;
    final duration = Duration(milliseconds: 400);

    final controller = AnimationController(vsync: this, duration: duration);

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);

    animation.addListener(() {
      double progress = animation.value;
      double offset = sin(progress * shakeCount * 3.14159) * shakeOffset;
      setState(() {});
    });

    controller.forward().then((_) => controller.dispose());
  }

  void _animateSuccess(VoidCallback onComplete) {
    // Simple bounce animation
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(controller);

    scaleAnimation.addListener(() {
      setState(() {});
    });

    controller.forward().then((_) {
      controller.dispose();
      onComplete();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Input Field with animation
                  FadeTransition(
                    opacity: _formAnimation,
                    child: _buildTextField(
                      controller: _titleController,
                      hint: 'Title',
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description Input Field with animation
                  FadeTransition(
                    opacity: _formAnimation,
                    child: _buildTextField(
                      controller: _postController,
                      hint: 'Share your thoughts...',
                      maxLines: 6,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Display selected attachments
                  if (_attachments.isNotEmpty) ...[
                    Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...List.generate(_attachments.length, (index) {
                      final attachment = _attachments[index];

                      if (_uploadingAttachments.contains(attachment)) {
                        return UploadingAttachmentWidget(
                          attachment: attachment,
                          progress:
                              _uploadProgress[attachment.fileName ?? ''] ?? 0.0,
                          themeColor: AppColors.primary,
                          onCancel: () => _removeAttachment(attachment),
                        );
                      } else {
                        return FileAttachmentWidget(
                          attachment: attachment,
                          themeColor: AppColors.primary,
                          onRemove: () => _removeAttachment(attachment),
                        );
                      }
                    }),

                    const SizedBox(height: 20),
                  ],

                  // Attachment picker with slide animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: AttachmentPickerWidget(
                      onAttachmentSelected: _handleAddAttachment,
                      themeColor: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Post Button with scale animation
                  ScaleTransition(
                    scale: _buttonAnimation,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handlePostSubmission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Posting...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                                : const Text(
                                  'Post',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
        ),
      ),
    );
  }
}
