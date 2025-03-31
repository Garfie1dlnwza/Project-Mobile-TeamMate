import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all documents for a department
  Stream<QuerySnapshot> getDocumentsByDepartmentId(String departmentId) {
    return _firestore
        .collection('documents')
        .where('departmentId', isEqualTo: departmentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get documents visible to a specific user
  Stream<QuerySnapshot> getVisibleDocumentsForUser({
    required String departmentId,
    String? userId,
  }) {
    // For non-authenticated users or missing userId, return empty stream
    if (userId == null) {
      return Stream.empty();
    }

    // Query documents that:
    // 1. Belong to this department AND
    // 2. Were created by this user OR are public
    return _firestore
        .collection('documents')
        .where('departmentId', isEqualTo: departmentId)
        .where(
          Filter.or(
            Filter('creatorId', isEqualTo: userId),
            Filter('visibility', isEqualTo: 'public'),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get a specific document by ID
  Future<DocumentSnapshot?> getDocumentById(String documentId) async {
    try {
      return await _firestore.collection('documents').doc(documentId).get();
    } catch (e) {
      print('Error getting document: $e');
      return null;
    }
  }

  // Create a new document
  Future<String?> createDocument({
    required String title,
    required String content,
    required String departmentId,
    required String creatorId,
    String visibility = 'public',
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('documents').add({
        'title': title,
        'content': content,
        'departmentId': departmentId,
        'creatorId': creatorId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'visibility': visibility,
        'attachments': attachments ?? [],
      });
      return docRef.id;
    } catch (e) {
      print('Error creating document: $e');
      return null;
    }
  }

  // Update an existing document
  Future<bool> updateDocument({
    required String documentId,
    String? title,
    String? content,
    String? visibility,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (visibility != null) updateData['visibility'] = visibility;
      if (attachments != null) updateData['attachments'] = attachments;

      await _firestore
          .collection('documents')
          .doc(documentId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating document: $e');
      return false;
    }
  }

  // Delete a document
  Future<bool> deleteDocument(String documentId) async {
    try {
      await _firestore.collection('documents').doc(documentId).delete();
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }
}
