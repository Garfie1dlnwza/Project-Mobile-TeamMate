import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleDriveFileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // คีย์ Client ID และ Client Secret จาก Google Cloud Console
  static const _clientId = "504293081632-q4tcbt2kqai8uu89ocn13mhvsrl6tm3i.apps.googleusercontent.com";
  static const _clientSecret = "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";

  // Scopes ที่ต้องการเข้าถึงใน Google Drive
  static final _scopes = [
    drive.DriveApi.driveFileScope, // สามารถอ่าน/เขียนไฟล์ที่แอปสร้างเท่านั้น
  ];

  // ชื่อโฟลเดอร์ในการเก็บไฟล์ทั้งหมดของแอป
  static const _appFolderName = "TeammateApp";

  // สร้าง AuthClient สำหรับเชื่อมต่อกับ Google Drive API
  Future<http.Client> _getAuthClient() async {
    if (kIsWeb) {
      // สำหรับเว็บใช้ OAuth2 ผ่าน Browser
      final authClient = await clientViaUserConsent(
        ClientId(_clientId, _clientSecret),
        _scopes,
        (url) async {
          // เปิด URL เพื่อให้ผู้ใช้ล็อกอิน
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
      );
      return authClient;
    } else {
      // สำหรับมือถือใช้ OAuth2 ผ่าน Browser เช่นกัน
      final authClient = await clientViaUserConsent(
        ClientId(_clientId, _clientSecret),
        _scopes,
        (url) async {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
      );
      return authClient;
    }
  }

  // ค้นหาหรือสร้างโฟลเดอร์สำหรับเก็บไฟล์แอป
  Future<String?> _getOrCreateAppFolder(drive.DriveApi driveApi) async {
    try {
      // ค้นหาโฟลเดอร์ของแอป
      final query =
          "mimeType='application/vnd.google-apps.folder' and name='$_appFolderName' and trashed=false";
      final result = await driveApi.files.list(q: query);

      if (result.files != null && result.files!.isNotEmpty) {
        // ใช้โฟลเดอร์ที่มีอยู่แล้ว
        return result.files!.first.id;
      } else {
        // สร้างโฟลเดอร์ใหม่
        final folder =
            drive.File()
              ..name = _appFolderName
              ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await driveApi.files.create(folder);
        return createdFolder.id;
      }
    } catch (e) {
      print('Error creating app folder: $e');
      return null;
    }
  }

  // สร้างโฟลเดอร์สำหรับแต่ละโปรเจคและดีพาร์ทเมนต์
  Future<String?> _getOrCreateProjectFolder(
    drive.DriveApi driveApi,
    String appFolderId,
    String departmentId,
    String projectId,
  ) async {
    try {
      // สร้างเส้นทางโฟลเดอร์ [AppFolder]/[DepartmentID]/[ProjectID]

      // 1. ตรวจสอบและสร้างโฟลเดอร์ดีพาร์ทเมนต์
      String deptFolderName = 'department_$departmentId';
      String deptQuery =
          "mimeType='application/vnd.google-apps.folder' and name='$deptFolderName' and '$appFolderId' in parents and trashed=false";
      var result = await driveApi.files.list(q: deptQuery);

      String deptFolderId;
      if (result.files != null && result.files!.isNotEmpty) {
        deptFolderId = result.files!.first.id!;
      } else {
        final deptFolder =
            drive.File()
              ..name = deptFolderName
              ..mimeType = 'application/vnd.google-apps.folder'
              ..parents = [appFolderId];

        final createdFolder = await driveApi.files.create(deptFolder);
        deptFolderId = createdFolder.id!;
      }

      // 2. ตรวจสอบและสร้างโฟลเดอร์โปรเจค
      String projFolderName = 'project_$projectId';
      String projQuery =
          "mimeType='application/vnd.google-apps.folder' and name='$projFolderName' and '$deptFolderId' in parents and trashed=false";
      result = await driveApi.files.list(q: projQuery);

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      } else {
        final projFolder =
            drive.File()
              ..name = projFolderName
              ..mimeType = 'application/vnd.google-apps.folder'
              ..parents = [deptFolderId];

        final createdFolder = await driveApi.files.create(projFolder);
        return createdFolder.id;
      }
    } catch (e) {
      print('Error creating project folder: $e');
      return null;
    }
  }

  /// อัปโหลดไฟล์ไปยัง Google Drive และบันทึกข้อมูลใน Firestore
  Future<String> createDocument({
    required String projectId,
    required String departmentId,
    required String title,
    required String? description,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    try {
      // ตรวจสอบข้อมูลที่จำเป็น
      if ((attachmentPath == null && attachmentBytes == null) ||
          attachmentName == null) {
        throw Exception('File is required');
      }

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to create a document');
      }

      // สร้าง ID เอกสารใหม่
      final String documentId = _uuid.v4();

      // 1. เชื่อมต่อกับ Google Drive API
      final client = await _getAuthClient();
      final driveApi = drive.DriveApi(client);

      // 2. หาหรือสร้างโฟลเดอร์หลักของแอป
      final appFolderId = await _getOrCreateAppFolder(driveApi);
      if (appFolderId == null) {
        throw Exception('Failed to create app folder in Google Drive');
      }

      // 3. หาหรือสร้างโฟลเดอร์สำหรับโปรเจคนี้
      final projectFolderId = await _getOrCreateProjectFolder(
        driveApi,
        appFolderId,
        departmentId,
        projectId,
      );
      if (projectFolderId == null) {
        throw Exception('Failed to create project folder in Google Drive');
      }

      // 4. อัปโหลดไฟล์
      final fileExtension = path.extension(attachmentName);
      final String uniqueFileName = '$documentId$fileExtension';

      // สร้างไฟล์บน Google Drive
      final driveFile =
          drive.File()
            ..name = uniqueFileName
            ..parents = [projectFolderId];

      late drive.File uploadedFile;

      // อัปโหลดตามประเภทข้อมูล (bytes หรือ file path)
      if (kIsWeb && attachmentBytes != null) {
        // อัปโหลดจาก bytes สำหรับเว็บ
        final stream = Stream<List<int>>.fromIterable([attachmentBytes]);
        uploadedFile = await driveApi.files.create(
          driveFile,
          uploadMedia: drive.Media(stream, attachmentBytes.length),
        );
      } else if (attachmentPath != null) {
        // อัปโหลดจากไฟล์บนมือถือ
        final file = File(attachmentPath);
        final fileSize = await file.length();
        final stream = file.openRead();
        uploadedFile = await driveApi.files.create(
          driveFile,
          uploadMedia: drive.Media(stream, fileSize),
        );
      } else {
        throw Exception('No valid file data provided');
      }

      // 5. ตั้งค่าการแชร์ไฟล์ให้เข้าถึงได้จาก URL
      await driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        uploadedFile.id!,
      );

      // 6. ดึง URL สำหรับเข้าถึงไฟล์
      final fileInfo =
          await driveApi.files.get(
                uploadedFile.id!,
                $fields: 'id,name,size,webViewLink,webContentLink',
              )
              as drive.File;

      final String downloadUrl = fileInfo.webContentLink ?? '';
      final String viewUrl = fileInfo.webViewLink ?? '';

      // 7. บันทึกข้อมูลเอกสารใน Firestore
      final documentData = {
        'id': documentId,
        'title': title,
        'description': description ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
        'creatorName': currentUser.displayName ?? 'Unknown User',
        'fileName': attachmentName,
        'fileSize': fileInfo.size ?? 0,
        'fileType': fileExtension.replaceAll('.', '').toLowerCase(),
        'downloadUrl': downloadUrl,
        'viewUrl': viewUrl,
        'fileId': uploadedFile.id,
        'departmentId': departmentId,
        'projectId': projectId,
      };

      // บันทึกใน Firestore
      await _firestore
          .collection('departments')
          .doc(departmentId)
          .collection('projects')
          .doc(projectId)
          .collection('posts')
          .doc(documentId)
          .set(documentData);

      // ปิด client เมื่อเสร็จสิ้น
      client.close();

      return documentId;
    } catch (e) {
      print('Error in createDocument: $e');
      rethrow;
    }
  }

  /// ลบเอกสารและไฟล์ที่เกี่ยวข้องจาก Google Drive
  Future<void> deleteDocument({
    required String documentId,
    required String departmentId,
    required String projectId,
    required String fileId,
  }) async {
    try {
      // 1. เชื่อมต่อกับ Google Drive API
      final client = await _getAuthClient();
      final driveApi = drive.DriveApi(client);

      // 2. ลบไฟล์จาก Google Drive
      await driveApi.files.delete(fileId);

      // 3. ลบข้อมูลเอกสารจาก Firestore
      await _firestore
          .collection('departments')
          .doc(departmentId)
          .collection('projects')
          .doc(projectId)
          .collection('posts')
          .doc(documentId)
          .delete();

      // ปิด client เมื่อเสร็จสิ้น
      client.close();
    } catch (e) {
      print('Error in deleteDocument: $e');
      rethrow;
    }
  }

  /// ดาวน์โหลดไฟล์จาก Google Drive
  Future<Uint8List> downloadFile(String fileId) async {
    try {
      // 1. เชื่อมต่อกับ Google Drive API
      final client = await _getAuthClient();
      final driveApi = drive.DriveApi(client);

      // 2. ดาวน์โหลดไฟล์
      final media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      // 3. อ่านข้อมูลไฟล์
      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }

      // ปิด client เมื่อเสร็จสิ้น
      client.close();

      return Uint8List.fromList(dataStore);
    } catch (e) {
      print('Error in downloadFile: $e');
      rethrow;
    }
  }
}
