import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class FileAttachment {
  final String? fileName;
  final String? fileSize;
  final String? fileType;
  final String? downloadUrl;
  final String? localPath;
  final Uint8List? fileBytes;
  final bool isImage;

  FileAttachment({
    this.fileName,
    this.fileSize,
    this.fileType,
    this.downloadUrl,
    this.localPath,
    this.fileBytes,
    this.isImage = false,
  });
}

class FileAttachmentService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // คำนวณหน่วยของขนาดไฟล์
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // เลือกรูปภาพจากแกลเลอรี่
  Future<FileAttachment?> pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        final String fileName = path.basename(pickedImage.path);
        Uint8List? imageBytes;
        String? localPath;
        int fileSize = 0;

        if (kIsWeb) {
          imageBytes = await pickedImage.readAsBytes();
          fileSize = imageBytes.length;
        } else {
          localPath = pickedImage.path;
          final File file = File(localPath);
          fileSize = await file.length();
        }

        return FileAttachment(
          fileName: fileName,
          fileSize: _formatFileSize(fileSize),
          fileType: 'IMAGE',
          localPath: localPath,
          fileBytes: imageBytes,
          isImage: true,
        );
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }

  // เลือกไฟล์ทั่วไป
  Future<FileAttachment?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null) {
        final file = result.files.single;
        final String fileSize = _formatFileSize(file.size);
        final String fileType = file.extension?.toUpperCase() ?? 'UNKNOWN';

        Uint8List? fileBytes;
        String? localPath;

        if (kIsWeb) {
          fileBytes = file.bytes;
        } else {
          localPath = file.path;
        }

        final bool isImage = [
          'JPG',
          'JPEG',
          'PNG',
          'GIF',
          'WEBP',
          'BMP',
        ].contains(fileType);

        return FileAttachment(
          fileName: file.name,
          fileSize: fileSize,
          fileType: fileType,
          localPath: localPath,
          fileBytes: fileBytes,
          isImage: isImage,
        );
      }
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  // อัพโหลดไฟล์ไปยัง Firebase Storage
  Future<FileAttachment?> uploadFile({
    required FileAttachment attachment,
    required String storagePath,
    Function(double)? onProgress,
  }) async {
    if ((attachment.fileBytes == null && attachment.localPath == null) ||
        attachment.fileName == null) {
      return null;
    }

    try {
      final String fileName = attachment.fileName!;
      final String storageRef =
          '$storagePath/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      UploadTask uploadTask;

      // เลือกวิธีอัพโหลดตามประเภทของข้อมูล (web หรือ mobile)
      if (kIsWeb && attachment.fileBytes != null) {
        uploadTask = _storage
            .ref(storageRef)
            .putData(
              attachment.fileBytes!,
              SettableMetadata(
                contentType: _getContentType(attachment.fileType ?? ''),
              ),
            );
      } else if (attachment.localPath != null) {
        uploadTask = _storage
            .ref(storageRef)
            .putFile(File(attachment.localPath!));
      } else {
        throw Exception('No file data available for upload');
      }

      // ติดตามความคืบหน้าการอัพโหลด
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (onProgress != null) {
          onProgress(progress);
        }
      });

      // รอให้อัพโหลดเสร็จและรับ URL
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return FileAttachment(
        fileName: attachment.fileName,
        fileSize: attachment.fileSize,
        fileType: attachment.fileType,
        downloadUrl: downloadUrl,
        isImage: attachment.isImage,
      );
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // กำหนด Content-Type ตามนามสกุลไฟล์
  String _getContentType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'txt':
        return 'text/plain';
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'json':
        return 'application/json';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }

  // ดาวน์โหลดไฟล์จาก URL (สำหรับเปิดไฟล์)
  Future<void> openFileFromUrl(String url) async {
    // ฟังก์ชั่นนี้จะทำงานร่วมกับแพ็กเกจที่จำเป็นต้องติดตั้งเพิ่ม
    // เช่น url_launcher หรือเปิดใน WebView
  }

  // ไอคอนสำหรับแต่ละประเภทไฟล์
  IconData getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}
