import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teammate/hardware/take_picture_screen.dart';
import 'package:teammate/services/firestore_noti_service.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:teammate/widgets/common/profile.dart';

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;

class ProfileEditCard extends StatefulWidget {
  final Function? onImageUpdated;

  const ProfileEditCard({super.key, this.onImageUpdated});

  @override
  State<ProfileEditCard> createState() => _ProfileEditCardState();
}

class _ProfileEditCardState extends State<ProfileEditCard> {
  bool _isLoading = false;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirestoreNotificationService _notificationService =
      FirestoreNotificationService();
  File? _selectedImage;

  Future<void> _selectImageFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // ลดขนาดรูปเพื่อประหยัดพื้นที่เก็บข้อมูล
        maxHeight: 800,
        imageQuality: 85, // คุณภาพรูป 85%
      );

      if (image != null) {
        File imageFile = File(image.path);
        setState(() {
          _selectedImage = imageFile;
        });
        await _uploadImageToFirebase(imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processImageFromCamera(File imageFile) async {
    try {
      setState(() {
        _isLoading = true;
        _selectedImage = imageFile;
      });

      await _uploadImageToFirebase(imageFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImageToFirebase(File imageFile) async {
    try {
      // รับข้อมูลผู้ใช้ปัจจุบัน
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      }

      // สร้างชื่อไฟล์ที่ไม่ซ้ำกัน
      final fileName =
          '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // กำหนด path ในการเก็บไฟล์บน Firebase Storage
      final storageRef = _storage.ref().child('profile_images/$fileName');

      // เริ่มอัพโหลดไฟล์
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType:
              'image/${path.extension(imageFile.path).replaceFirst('.', '')}',
        ),
      );

      // ติดตามความคืบหน้าในการอัพโหลด (สามารถแสดงผลให้ผู้ใช้เห็นได้ในอนาคต)
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        },
        onError: (e) {
          print('อัพโหลดไฟล์ล้มเหลว: $e');
        },
      );

      // รอให้อัพโหลดเสร็จสิ้น
      await uploadTask.whenComplete(() => print('อัพโหลดเสร็จสิ้น'));

      // รับ URL ของไฟล์ที่อัพโหลด
      final downloadUrl = await storageRef.getDownloadURL();

      // อัปเดตโปรไฟล์ของผู้ใช้ใน Firebase Auth
      await currentUser.updatePhotoURL(downloadUrl);

      // แจ้งเตือนให้ผู้ใช้ทราบว่าอัพโหลดสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัพโหลดรูปโปรไฟล์สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // ส่งการแจ้งเตือนผู้ใช้เกี่ยวกับการอัพเดตรูปโปรไฟล์
      await _sendProfileUpdateNotification();

      // เรียกใช้ callback หากมีการกำหนด
      if (widget.onImageUpdated != null) {
        widget.onImageUpdated!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัพโหลดรูปโปรไฟล์ล้มเหลว: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('เกิดข้อผิดพลาดในการอัพโหลดรูปโปรไฟล์: $e');
    }
  }

  // เพิ่มเมธอดสำหรับส่งการแจ้งเตือนเมื่ออัพเดตรูปโปรไฟล์
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
      // Silent fail - ไม่ให้มีผลกับการอัพเดทรูปโปรไฟล์
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
                  'เลือกรูปภาพ',
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
                    Navigator.of(context).pop(); // ปิด bottom sheet ก่อน

                    final cameras = await availableCameras();
                    if (cameras.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ไม่พบกล้องบนอุปกรณ์นี้'),
                          ),
                        );
                      }
                      return;
                    }

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TakePictureScreen(cameras: cameras),
                      ),
                    );

                    // จัดการกับไฟล์รูปภาพที่ได้รับกลับมา
                    if (result != null && result is File) {
                      await _processImageFromCamera(result);
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
                  // ถ้าผู้ใช้มีรูปโปรไฟล์ในระบบ ให้แสดงรูปนั้น หรือถ้ามีการเลือกรูปใหม่ ให้แสดงรูปที่เลือก
                  if (_selectedImage != null)
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
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(user!.photoURL!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    ProfileAvatar(name: displayName, size: 120),

                  if (_isLoading)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGradientEnd.withOpacity(0.5),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.background,
                          ),
                        ),
                      ),
                    ),

                  // Edit button
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _showImageSourceOptions,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
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
            ],
          ),
        ),
      ),
    );
  }
}
