import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditCard extends StatefulWidget {
  final Function? onImageUpdated;

  const ProfileEditCard({Key? key, this.onImageUpdated}) : super(key: key);

  @override
  State<ProfileEditCard> createState() => _ProfileEditCardState();
}

class _ProfileEditCardState extends State<ProfileEditCard> {
  bool _isLoading = false;

  Future<void> _selectImageFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (widget.onImageUpdated != null) {
        widget.onImageUpdated!();
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

  Future<void> _selectImageFromCamera() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      // if (image != null) {
      //   File imageFile = File(image.path);
      //   String? imageUrl = await SupabaseService.uploadToSupabase(imageFile);

      //   if (imageUrl != null && widget.onImageUpdated != null) {
      //     widget.onImageUpdated!();
      //   }
      // }
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

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 0, 50),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selectImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Library'),
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
    return Card(
      shadowColor: Colors.transparent,
      color: Colors.transparent,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
        child: Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image:
                            FirebaseAuth.instance.currentUser?.photoURL != null
                                ? NetworkImage(
                                  FirebaseAuth.instance.currentUser!.photoURL!,
                                )
                                : const AssetImage('assets/images/default.png')
                                    as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // color: const Color.fromARGB(0, 255, 255, 255).withOpacity(0.5),
                      ),
                      child: const Center(
                        // child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _showImageSourceOptions,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
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
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.75,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
