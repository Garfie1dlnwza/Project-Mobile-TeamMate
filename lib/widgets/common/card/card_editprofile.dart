import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teammate/hardware/take_picture_screen.dart';
import 'package:teammate/services/firestore_noti_service.dart';
import 'package:teammate/services/profile_service.dart'; // New service
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/widgets/common/profile.dart';


import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ProfileEditCard extends StatefulWidget {
  final Function? onImageUpdated;
  final bool showEditButton;

  const ProfileEditCard({
    super.key,
    this.onImageUpdated,
    this.showEditButton = true,
  });

  @override
  State<ProfileEditCard> createState() => _ProfileEditCardState();
}

class _ProfileEditCardState extends State<ProfileEditCard> {
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirestoreNotificationService _notificationService =
      FirestoreNotificationService();
  final ProfileService _profileService = ProfileService();
  File? _selectedImage;
  String? _errorMessage;

  Future<void> _selectImageFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        // Compress the image before uploading
        final File compressedImage = await _compressImage(File(image.path));

        setState(() {
          _selectedImage = compressedImage;
        });
        await _uploadImageToFirebase(compressedImage);
      } else {
        // User canceled image selection
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: ${e.toString()}';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${path.basename(file.path)}';

    // Compress with quality 85%
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 85,
      minWidth: 800,
      minHeight: 800,
    );

    if (result == null) {
      // If compression fails, return the original file
      return file;
    }
    return File(result.path);
  }

  Future<void> _processImageFromCamera(File imageFile) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _selectedImage = imageFile;
      });

      // Compress the image before uploading
      final File compressedImage = await _compressImage(imageFile);

      setState(() {
        _selectedImage = compressedImage;
      });
      await _uploadImageToFirebase(compressedImage);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing image: ${e.toString()}';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadImageToFirebase(File imageFile) async {
    try {
      // Reset upload progress and error state
      setState(() {
        _uploadProgress = 0.0;
        _errorMessage = null;
      });

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not found. Please login again');
      }

      // Generate unique filename
      final fileName =
          '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Define storage reference
      final storageRef = _storage.ref().child('profile_images/$fileName');

      // Start upload with proper content type
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType:
              'image/${path.extension(imageFile.path).replaceFirst('.', '')}',
        ),
      );

      // Track upload progress
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            _uploadProgress = progress;
          });
          print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        },
        onError: (e) {
          setState(() {
            _errorMessage = 'File upload failed: $e';
            _isLoading = false;
          });
          print('File upload failed: $e');
        },
      );

      // Wait for upload to complete
      await uploadTask.whenComplete(() => print('Upload completed'));

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update user profile in Firebase Auth
      await currentUser.updatePhotoURL(downloadUrl);

      // Update Firestore user document if needed
      await _profileService.updateUserProfileImage(
        currentUser.uid,
        downloadUrl,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Send notification about profile update
      await _sendProfileUpdateNotification();

      // Call callback if provided
      if (widget.onImageUpdated != null) {
        widget.onImageUpdated!();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload profile picture: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
      print('Error uploading profile picture: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Send notification when profile is updated
  Future<void> _sendProfileUpdateNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _notificationService.createNotification(
        userId: user.uid,
        type: 'profile_update',
        message: 'Your profile picture has been updated successfully',
        additionalData: {
          'updateType': 'profile_picture',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error sending profile update notification: $e');
      // Silent fail - doesn't affect the profile picture update
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Select Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGradientStart.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop(); // Close bottom sheet

                    final cameras = await availableCameras();
                    if (cameras.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No camera found on this device'),
                          ),
                        );
                      }
                      return;
                    }

                    if (mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TakePictureScreen(cameras: cameras),
                        ),
                      );

                      // Process camera image if returned
                      if (result != null && result is File) {
                        await _processImageFromCamera(result);
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGradientStart.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Choose from Library',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selectImageFromGallery();
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'User';
    final String email = user?.email ?? '';
    final bool hasPhoto = user?.photoURL != null;

    return Card(
      shadowColor: Colors.transparent,
      color: AppColors.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Profile image display options
                  if (_selectedImage != null)
                    // Show selected image before upload completes
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else if (hasPhoto)
                    // Show cached network image for better performance
                    ClipOval(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: user!.photoURL!,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: AppColors.secondary.withOpacity(0.2),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary.withOpacity(0.5),
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  ProfileAvatar(name: displayName, size: 120),
                        ),
                      ),
                    )
                  else
                    // Default avatar when no image is available
                    ProfileAvatar(name: displayName, size: 120),

                  // Loading overlay with progress indicator
                  if (_isLoading)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGradientEnd.withOpacity(0.7),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.background,
                              ),
                              strokeWidth: 3,
                              value:
                                  _uploadProgress > 0 ? _uploadProgress : null,
                            ),
                          ),
                          if (_uploadProgress > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Edit button
                  if (widget.showEditButton)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _showImageSourceOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: AppColors.background,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.75,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.secondary,
                ),
              ),

              // Error message if any
              if (_errorMessage != null && _errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
