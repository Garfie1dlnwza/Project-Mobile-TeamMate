import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUserService {
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');
  
  // Get user data by ID
  Future<DocumentSnapshot> getUserById(String userId) async {
    return await _usersCollection.doc(userId).get();
  }

  // Get user's display name by ID
  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        // Try to get display name, full name, or return userId if not found
        return userData['displayName'] ?? 
               userData['fullName'] ?? 
               userData['name'] ?? 
               userData['firstName'] + ' ' + userData['lastName'] ?? 
               'User-$userId';
      }
      return 'Unknown User';
    } catch (e) {
      print('Error getting user name: $e');
      return 'Unknown User';
    }
  }
  
  // Create or update user data
  Future<void> setUserData(String userId, Map<String, dynamic> userData) async {
    await _usersCollection.doc(userId).set(userData, SetOptions(merge: true));
  }
  
  // Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> userData) async {
    await _usersCollection.doc(userId).update(userData);
  }
  
  // Check if user exists
  Future<bool> checkUserExists(String userId) async {
    DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
    return userDoc.exists;
  }
  
  // Get a stream of user data for realtime updates
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots();
  }
}