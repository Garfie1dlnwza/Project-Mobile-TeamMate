import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );
  bool _isLoading = true;
  String? _userName;

  get getUserName => this._userName;

  Future<void> fetchUserName() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (userDoc.exists && userDoc.data() != null) {
          _userName =
              userDoc['name']; // Assuming 'name' is the field in your Firestore document
          _isLoading = false;
        }
      } else {
        _isLoading = false;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _isLoading = false;
    }
  }

  Future<UserModel?> registerAccount({required UserModel userModel}) async {
    try {
      // Creaate Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: userModel.email,
            password: userModel.password,
          );
      // update userModel ด้วย UID
      UserModel updatedUserModel = userModel.copyWith(
        id: userCredential.user!.uid,
      );

      // save to Firestore โดยใช้ UID เป็น Document ID
      await users.doc(userCredential.user!.uid).set({
        'id': updatedUserModel.id,
        'email': updatedUserModel.email,
        'name': updatedUserModel.name,
        'phone': updatedUserModel.phoneNumber,
        'projects': updatedUserModel.projects,
        'profileImage': updatedUserModel.profileImage,
      });

      return updatedUserModel;
    } catch (e) {
      print("🔥 Error in registerAccount: $e");
      return null;
    }
  }

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
          await users.where('email', isEqualTo: email).get();

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

  /// 🔹 ออกจากระบบ
  Future<void> SignOut() async {
    await _auth.signOut();
  }
}
