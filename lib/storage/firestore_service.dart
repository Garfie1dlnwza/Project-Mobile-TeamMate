import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Save user data
  Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    await _firebaseFirestore.collection('users').doc(userId).set(data);
  }

  // Fetch user data
  Future<DocumentSnapshot> fetchUserData(String userId) async {
    return await _firebaseFirestore.collection('users').doc(userId).get();
  }
}
