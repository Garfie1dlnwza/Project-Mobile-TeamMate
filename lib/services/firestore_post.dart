import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPost({
    required String creatorId,
    required String title,
    required String description,
    required String departmentId,
    String? imageUrl,
    String? fileUrl,
  }) async {
    try {
      await _firestore.collection('posts').add({
        'creator': creatorId,
        'title': title,
        'description': description,
        'image': imageUrl ?? '',
        'file': fileUrl ?? '',
        'departmentId': departmentId,
        'createdAt': FieldValue.serverTimestamp(),
        'comments': '',
      });
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Stream<QuerySnapshot> getPostsForDepartmentId(String departmentId) {
    return _firestore
        .collection('posts')
        .where('departmentId', isEqualTo: departmentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
