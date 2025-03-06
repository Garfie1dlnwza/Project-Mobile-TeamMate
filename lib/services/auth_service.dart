// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teammate/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Save login state
  Future<void> saveLoginState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', userId);
  }

  // Clear login state (logout)
  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    await _auth.signOut();
  }

  // Get user from Firestore
  Future<UserModel?> getUserFromFirestore(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        Map<String, dynamic> userData = docSnapshot.data()!;
        userData['id'] = userId; // Add ID to the data
        return UserModel.fromMap(userData);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    String? userId = await getCurrentUserId();
    if (userId != null) {
      return await getUserFromFirestore(userId);
    }
    return null;
  }

  // Register new user
  Future<UserModel?> registerUser({required UserModel userModel}) async {
    try {
      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: userModel.password!,
      );

      // Get user ID
      String uid = result.user!.uid;

      // Create a new user model with the ID
      UserModel newUser = UserModel(
        id: uid,
        name: userModel.name,
        email: userModel.email,
        password: userModel.password,
        phoneNumber: userModel.phoneNumber,
        profileImage: userModel.profileImage,
        projects: userModel.projects,
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      // Save login state
      await saveLoginState(uid);

      return newUser;
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = result.user!.uid;

      // Get user data from Firestore
      UserModel? user = await getUserFromFirestore(uid);

      if (user != null) {
        // Save login state
        await saveLoginState(uid);
        return user;
      }

      return null;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }
}
