import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Collection reference for users
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Cache control
  static const String _cacheKeyPrefix = 'profile_image_timestamp_';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isUserLoggedIn => currentUser != null;

  // Get profile image URL with cache busting if needed
  Future<String?> getProfileImageUrl() async {
    final user = currentUser;
    if (user == null || user.photoURL == null) return null;

    // Add cache busting parameter if needed
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_cacheKeyPrefix${user.uid}');

    if (timestamp != null) {
      // If URL already has query parameters
      if (user.photoURL!.contains('?')) {
        return '${user.photoURL!}&_cb=$timestamp';
      } else {
        return '${user.photoURL!}?_cb=$timestamp';
      }
    }

    return user.photoURL;
  }

  // Update cache timestamp for a user
  Future<void> _updateCacheTimestamp(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_cacheKeyPrefix$userId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery({
    double maxWidth = 800,
    double maxHeight = 800,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedImage == null) return null;

      return File(pickedImage.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Compress image to reduce upload size
  Future<File> compressImage(
    File file, {
    int quality = 85,
    int minWidth = 800,
    int minHeight = 800,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${path.basename(file.path)}';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );

      if (result == null) {
        // If compression fails, return original
        return file;
      }

      return File(result.path);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      // Return original on error
      return file;
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(
    File imageFile, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Generate unique filename
      final String fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String storagePath = 'profile_images/$fileName';

      // Get file mime type
      final String mimeType =
          'image/${path.extension(imageFile.path).replaceFirst('.', '')}';

      // Create upload task
      final storageRef = _storage.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: mimeType),
      );

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (onProgress != null) {
          onProgress(progress);
        }
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update cache timestamp
      await _updateCacheTimestamp(user.uid);

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  // Update user profile with new image URL
  Future<bool> updateUserProfileImage(String userId, String imageUrl) async {
    try {
      // Update Firebase Auth profile
      if (currentUser?.uid == userId) {
        await currentUser!.updatePhotoURL(imageUrl);
      }

      // Update Firestore user document
      await _usersCollection.doc(userId).update({
        'imageURL': imageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update cache timestamp
      await _updateCacheTimestamp(userId);

      return true;
    } catch (e) {
      debugPrint('Error updating user profile image: $e');
      return false;
    }
  }

  // Complete profile image update process
  Future<bool> updateProfileImage(
    File imageFile, {
    Function(double progress)? onProgress,
    bool compressBeforeUpload = true,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Compress image if requested
      File fileToUpload = imageFile;
      if (compressBeforeUpload) {
        fileToUpload = await compressImage(imageFile);
      }

      // Upload to Firebase Storage
      final downloadUrl = await uploadProfileImage(
        fileToUpload,
        onProgress: onProgress,
      );

      if (downloadUrl == null) {
        throw Exception('Failed to get download URL');
      }

      // Update user profile
      final success = await updateUserProfileImage(user.uid, downloadUrl);

      return success;
    } catch (e) {
      debugPrint('Error in updateProfileImage: $e');
      return false;
    }
  }

  // Get user details from Firestore
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user details: $e');
      return null;
    }
  }

  // Delete previous profile image from storage if exists
  Future<void> deleteOldProfileImage() async {
    try {
      final user = currentUser;
      if (user == null || user.photoURL == null) return;

      // Extract reference path from URL
      final Uri uri = Uri.parse(user.photoURL!);
      final String path = uri.path;

      // Remove the "/o/" prefix and decode the path
      if (path.startsWith('/o/')) {
        final String storagePath = Uri.decodeComponent(path.substring(3));
        final Reference ref = _storage.ref().child(storagePath);

        // Delete the file
        await ref.delete();
        debugPrint('Old profile image deleted successfully');
      }
    } catch (e) {
      // Silently fail, this is a cleanup operation
      debugPrint('Error deleting old profile image: $e');
    }
  }

  // Update only specific fields of user profile
  Future<bool> updateUserFields(Map<String, dynamic> fields) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await _usersCollection.doc(user.uid).update(fields);
      return true;
    } catch (e) {
      debugPrint('Error updating user fields: $e');
      return false;
    }
  }
}
