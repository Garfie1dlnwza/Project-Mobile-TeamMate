import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

class FileService {
  Future<String> createDocument({
    required String projectId,
    required String departmentId,
    required String title,
    String? description,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    try {
      String documentId = Uuid().v4();
      String savedFilePath;

      if (kIsWeb && attachmentBytes != null && attachmentName != null) {
        // บันทึกไฟล์ใน Web Storage (ถ้าจำเป็น)
        savedFilePath = attachmentName;
      } else if (attachmentPath != null) {
        // คัดลอกไฟล์ไปยังโฟลเดอร์ภายในแอป
        final Directory appDir = await getApplicationDocumentsDirectory();
        savedFilePath = '${appDir.path}/$attachmentName';
        await File(attachmentPath).copy(savedFilePath);
      } else {
        throw Exception("ไม่พบไฟล์แนบ");
      }

      var documentsBox = await Hive.openBox<Map>('documents');
      await documentsBox.put(documentId, {
        'id': documentId,
        'title': title,
        'description': description,
        'projectId': projectId,
        'departmentId': departmentId,
        'attachmentPath': savedFilePath,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await documentsBox.close();

      var departmentsBox = await Hive.openBox<Map>('departments');
      Map? departmentData = departmentsBox.get(departmentId);
      
      if (departmentData != null) {
        List<dynamic> documents = departmentData['documents'] ?? [];
        if (!documents.contains(documentId)) {
          documents.add(documentId);
        }
        departmentData['documents'] = documents;
        await departmentsBox.put(departmentId, departmentData);
      }
      await departmentsBox.close();

      return documentId;
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      rethrow;
    }
  }
}
