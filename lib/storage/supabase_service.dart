import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class SupabaseService {
  static final supabase = Supabase.instance.client;
  static final firebase = firebase_auth.FirebaseAuth.instance;

  /// อัปโหลดไฟล์ไปยัง Supabase Storage โดยใช้ Firebase User ID
  static Future<String?> uploadToSupabase(dynamic file) async {
    // รับ Firebase User ID
    final firebaseUser = firebase.currentUser;
    if (firebaseUser == null) {
      print("ไม่พบข้อมูลผู้ใช้ Firebase กรุณาล็อกอินก่อนอัปโหลดไฟล์");
      return null;
    }
    
    // นำ Firebase UID มาใช้เป็นชื่อโฟลเดอร์
    final userId = firebaseUser.uid;
    String extension = '';
    
    // ตรวจสอบประเภทของไฟล์และดึงนามสกุล
    if (!kIsWeb && file is File) {
      extension = file.path.split('.').last.toLowerCase();
    } else {
      extension = 'png';
    }
    
    // รวม user ID ในชื่อไฟล์
    String fileName = 'user_${userId}/${DateTime.now().millisecondsSinceEpoch}.$extension';
    
    try {
      // อัปโหลดไฟล์ตามแพลตฟอร์ม
      if (kIsWeb && file is Uint8List) {
        // สำหรับเว็บ: ใช้ uploadBinary กับ Uint8List
        await supabase.storage.from('user_images').uploadBinary(
              fileName,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
      } else if (!kIsWeb && file is File) {
        // สำหรับมือถือ: ใช้ upload กับ File
        await supabase.storage.from('user_images').upload(
              fileName,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
      } else {
        throw Exception('Unsupported file type');
      }

      // ดึง URL สาธารณะของไฟล์ที่อัปโหลด
      final String publicUrl = supabase.storage.from('user_images').getPublicUrl(fileName);
      print("อัปโหลดสำเร็จ: $publicUrl");
      return publicUrl;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการอัปโหลด: $e");
      return null;
    }
  }

  /// เลือกรูปภาพจาก Gallery และอัปโหลดไปยัง Supabase
  static Future<String?> pickAndUploadImage() async {
    final picker = ImagePicker();
    try {
      // เลือกรูปภาพจาก Gallery
      final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage == null) {
        return null;
      }
      
      // ตรวจสอบนามสกุลไฟล์
      final extension = pickedImage.name.split('.').last.toLowerCase();
      if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
        print("นามสกุลไฟล์ไม่ถูกต้อง อนุญาตเฉพาะ .jpg, .jpeg และ .png");
        return null;
      }
      
      // ดำเนินการตามแพลตฟอร์ม
      if (kIsWeb) {
        // สำหรับเว็บ: อ่านข้อมูลเป็น Uint8List
        final bytes = await pickedImage.readAsBytes();
        return await uploadToSupabase(bytes);
      } else {
        // สำหรับมือถือ: ใช้ File
        File imageFile = File(pickedImage.path);
        return await uploadToSupabase(imageFile);
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเลือกหรืออัปโหลดรูปภาพ: $e");
      return null;
    }
  }

  /// ลบรูปภาพจาก Supabase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // ดึงชื่อไฟล์จาก URL
      String fileName = imageUrl.split('user_images/')[1]; // รับส่วนที่ตามหลัง 'user_images/'
      
      // ลบไฟล์จาก storage
      await supabase.storage.from('user_images').remove([fileName]);
      print("ลบรูปภาพสำเร็จ: $fileName");
      return true;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการลบรูปภาพ: $e");
      return false;
    }
  }

  /// ทดสอบการเชื่อมต่อกับ Supabase (Anon Key)
  static Future<bool> testSupabaseConnection() async {
    try {
      // ทดสอบการเชื่อมต่อโดยดึงข้อมูลจำนวน bucket
      final List<Bucket> buckets = await supabase.storage.listBuckets();
      print("เชื่อมต่อ Supabase สำเร็จ: ${buckets.length} buckets");
      return true;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเชื่อมต่อ Supabase: $e");
      return false;
    }
  }
}