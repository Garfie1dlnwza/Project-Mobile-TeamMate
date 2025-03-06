import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/models/user_model.dart';

class UserApi {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference userApi = FirebaseFirestore.instance.collection(
    'user',
  );

  /// 🔹 ลงทะเบียนบัญชีใหม่ และบันทึกลง Firestore
  Future<UserModel?> registerAccount({required UserModel userModel}) async {
    try {
      // ✅ สร้างบัญชีใน Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: userModel.email,
            password: userModel.password,
          );

      // Update the user model with the created UID
      UserModel updatedUserModel = userModel.copyWith(
        id: userCredential.user!.uid,
      );

      // ✅ บันทึกลง Firestore - using the UID as the document ID
      // Create a map for Firestore without the password
      // Map<String, dynamic> userDataForFirestore = updatedUserModel.toMap();
      // print(userCredential.user?.uid);
      final payload = {
        'id': userCredential.user?.uid,
        'email': userModel.email,
        'name': userModel.name,
        'phone': userModel.phoneNumber,
        'projects': userModel.projects,
        'profileImage': userModel.profileImage,
      };
      // print(payload);
      await userApi.doc(userCredential.user!.uid).set(payload);
      return updatedUserModel;
    } catch (e) {
      print("🔥 Error in registerAccount: $e");
      return null;
    }
  }

  /// 🔹 เข้าสู่ระบบด้วย Email & Password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = userCredential.user;
      if (firebaseUser?.uid == null) return null;

      // ค้นหาเอกสารที่มี email ตรงกับที่ระบุ
      QuerySnapshot querySnapshot =
          await userApi.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isEmpty) return null;

      // ใช้เอกสารแรกที่พบ
      DocumentSnapshot userDoc = querySnapshot.docs.first;

      UserModel user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
      );
      return user;
    } catch (e) {
      print("🔥 Error in signInWithEmail: $e");
      return null;
    }
  }

  /// 🔹 ออกจากระบบ
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
