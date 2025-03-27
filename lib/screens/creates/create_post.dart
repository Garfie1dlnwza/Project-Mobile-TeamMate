import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_post.dart';
import 'package:teammate/theme/app_colors.dart';

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
  bool _isSubmitting = false;

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

  Future<void> _handlePostSubmission() async {
    final title = _titleController.text.trim();
    final postText = _postController.text.trim();

    if (title.isEmpty || postText.isEmpty) {
      _showErrorSnackBar(
        title.isEmpty ? 'Please enter a title' : 'Please enter post content',
      );
      // Add shake animation for error
      _animateError();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _postService.createPost(
        creatorId: user!.uid,
        title: title,
        description: postText,
        departmentId: widget.departmentId,
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
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to create post: $e');
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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

              // Attachment Icons Container with slide animation
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
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
                        icon: Icons.photo_library_outlined,
                        label: 'Photo',
                        color: Colors.green.shade600,
                        onTap: () => print('Pick image'),
                      ),
                      _buildAttachmentOption(
                        icon: Icons.mic_outlined,
                        label: 'Voice',
                        color: Colors.blue.shade600,
                        onTap: () => print('Start recording'),
                      ),
                      _buildAttachmentOption(
                        icon: Icons.attach_file_outlined,
                        label: 'File',
                        color: Colors.orange.shade600,
                        onTap: () => print('Pick file'),
                      ),
                    ],
                  ),
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
                            ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'POST',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: InkWell(
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
      ),
    );
  }
}
