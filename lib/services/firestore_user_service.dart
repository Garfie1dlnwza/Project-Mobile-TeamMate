import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreUserService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  Future<void> createOrUpdateUser(
    String userId,
    String name,
    String email, {
    List<String>? projectIds,
    String? notiId,
  }) async {
    try {
      await _usersCollection.doc(userId).set({
        'uid': userId,
        'name': name,
        'email': email,
        'projectIds': projectIds ?? [],
        'notiId': notiId,
        'lastLogin': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error creating or updating user: $e");
    }
  }

  Future<DocumentSnapshot> getUserById(String userId) async {
    try {
      return await _usersCollection.doc(userId).get();
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> findNameById(String id) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(id).get();
      if (!userDoc.exists) {
        print("User not found for ID: $id");
        return null;
      }
      return userDoc['name'] as String?;
    } catch (e) {
      print("Error finding user by ID: $e");
      return null;
    }
  }

  Future<List<String>> getUserProjects(String userId) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        return List<String>.from(userDoc['projectIds'] ?? []);
      }
    } catch (e) {
      print("Error getting user projects: $e");
    }
    return [];
  }

  Future<void> updateUserProjects(String userId, String projectIds) async {
    try {
      await _usersCollection.doc(userId).update({
        'projectIds': FieldValue.arrayUnion([projectIds]),
      });
    } catch (e) {
      print("Error updating user projects: $e");
    }
  }

  Future<String?> getUserNotiId(String userId) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        return userDoc['notiId'] as String?;
      }
    } catch (e) {
      print("Error getting notification ID: $e");
    }
    return null;
  }

  Future<void> updateUserNotiId(String userId, String notiId) async {
    try {
      await _usersCollection.doc(userId).update({'notiId': notiId});
    } catch (e) {
      print("Error updating notification ID: $e");
    }
  }

// Get user ID by email
  Future<String?> getUserIdByEmail(String email) async {
    try {
      // Query the users collection to find a user with the matching email
      QuerySnapshot querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // If a user is found, return their user ID
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      // Return null if no user is found with the given email
      return null;
    } catch (e) {
      print("Error retrieving user ID by email: $e");
      return null;
    }
  }
}
