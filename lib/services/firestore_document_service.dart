import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new document
  Future<String?> createDocument({
    required String departmentId,
    required String projectId,
    required String title,
    required String description,
    required List<Map<String, dynamic>> attachments,
  }) async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create document in top-level collection (similar to tasks)
      DocumentReference docRef = _firestore.collection('documents').doc();
      final String documentId = docRef.id;

      // Prepare document data
      Map<String, dynamic> documentData = {
        'documentId': documentId,
        'title': title.trim(),
        'description': description.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'uploadedBy': currentUser.uid,
        'uploadedByName': currentUser.displayName,
        'departmentId': departmentId,
        'projectId': projectId,
        'attachments': attachments,
      };

      // Add main document info for backward compatibility
      if (attachments.isNotEmpty) {
        final mainAttachment = attachments.first;
        documentData.addAll({
          'fileName': mainAttachment['fileName'],
          'fileType': mainAttachment['fileType'],
          'fileSize': mainAttachment['fileSize'],
          'downloadUrl': mainAttachment['downloadUrl'],
        });
      }

      // Save document to Firestore
      await docRef.set(documentData);

      // Add document ID to department's documents array (optional)
      try {
        await _firestore.collection('departments').doc(departmentId).update({
          'documents': FieldValue.arrayUnion([docRef.id]),
        });
      } catch (e) {
        // If department doesn't have documents array, create it
        debugPrint('Error updating department documents array: $e');
        try {
          await _firestore.collection('departments').doc(departmentId).set({
            'documents': [docRef.id],
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error creating department documents array: $e');
        }
      }

      // Create a feed item for this document
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('feed')
          .add({
            'type': 'document',
            'createdAt': FieldValue.serverTimestamp(),
            'departmentId': departmentId,
            'projectId': projectId,
            'documentId': documentId,
            'data': documentData,
          });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating document: $e');
      return null;
    }
  }

  // Get documents by department ID
  Stream<QuerySnapshot> getDocumentsByDepartmentId(String departmentId) {
    try {
      return _firestore
          .collection('documents')
          .where('departmentId', isEqualTo: departmentId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error getting documents by department ID: $e');
      // Return an empty stream in case of error
      return Stream<QuerySnapshot>.empty();
    }
  }

  // Get documents by project ID
  Stream<QuerySnapshot> getDocumentsByProjectId(String projectId) {
    try {
      return _firestore
          .collection('documents')
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error getting documents by project ID: $e');
      // Return an empty stream in case of error
      return Stream<QuerySnapshot>.empty();
    }
  }

  // Get documents by user ID (documents uploaded by a specific user)
  Stream<QuerySnapshot> getDocumentsByUserId(String userId) {
    try {
      return _firestore
          .collection('documents')
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error getting documents by user ID: $e');
      return Stream<QuerySnapshot>.empty();
    }
  }

  // Get a specific document by ID
  Future<DocumentSnapshot?> getDocumentById(String documentId) async {
    try {
      return _firestore.collection('documents').doc(documentId).get();
    } catch (e) {
      debugPrint('Error fetching document: $e');
      return null;
    }
  }

  // Update document title and description
  Future<bool> updateDocument(
    String documentId,
    String title,
    String description,
  ) async {
    try {
      await _firestore.collection('documents').doc(documentId).update({
        'title': title.trim(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating document: $e');
      return false;
    }
  }

  // Add new attachment to existing document
  Future<bool> addAttachmentToDocument(
    String documentId,
    Map<String, dynamic> newAttachment,
  ) async {
    try {
      await _firestore.collection('documents').doc(documentId).update({
        'attachments': FieldValue.arrayUnion([newAttachment]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding attachment to document: $e');
      return false;
    }
  }

  // Remove attachment from document
  Future<bool> removeAttachmentFromDocument(
    String documentId,
    String attachmentUrl,
  ) async {
    try {
      // First get the document to find the attachment to remove
      DocumentSnapshot doc =
          await _firestore.collection('documents').doc(documentId).get();
      if (!doc.exists) return false;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> attachments = List.from(data['attachments'] ?? []);

      // Find the attachment with the matching URL
      int indexToRemove = attachments.indexWhere(
        (attachment) =>
            attachment is Map && attachment['downloadUrl'] == attachmentUrl,
      );

      if (indexToRemove != -1) {
        // Remove the attachment
        attachments.removeAt(indexToRemove);

        // Update the document with the modified attachments list
        await _firestore.collection('documents').doc(documentId).update({
          'attachments': attachments,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error removing attachment from document: $e');
      return false;
    }
  }

  // Delete a document
  Future<bool> deleteDocument(String documentId, String departmentId) async {
    try {
      // Remove document from department's documents array
      try {
        await _firestore.collection('departments').doc(departmentId).update({
          'documents': FieldValue.arrayRemove([documentId]),
        });
      } catch (e) {
        debugPrint('Error removing document from department array: $e');
        // Continue with deletion even if this fails
      }

      // Get the document to check for project ID
      DocumentSnapshot doc =
          await _firestore.collection('documents').doc(documentId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String projectId = data['projectId'] ?? '';

        // Delete feed items related to this document if project ID is available
        if (projectId.isNotEmpty) {
          try {
            QuerySnapshot feedItems =
                await _firestore
                    .collection('projects')
                    .doc(projectId)
                    .collection('feed')
                    .where('documentId', isEqualTo: documentId)
                    .get();

            for (var item in feedItems.docs) {
              await item.reference.delete();
            }
          } catch (e) {
            debugPrint('Error deleting document feed items: $e');
            // Continue with document deletion
          }
        }
      }

      // Delete the document
      await _firestore.collection('documents').doc(documentId).delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  // Get document count by department ID
  Future<int?> getDocumentCountByDepartmentId(String departmentId) async {
    try {
      final snapshot =
          await _firestore
              .collection('documents')
              .where('departmentId', isEqualTo: departmentId)
              .count()
              .get();

      return snapshot.count;
    } catch (e) {
      debugPrint('Error getting document count: $e');
      return 0;
    }
  }
}
