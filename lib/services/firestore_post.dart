import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestorePostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        'okReactions': [],
        'okCount': 0,
        'commentCount': 0,
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

  // Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String comment,
  }) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create comment data
      Map<String, dynamic> commentData = {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous User',
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add comment to subcollection
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(commentData);

      // Update the comment count in the post document
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Get comments for a post
  Stream<QuerySnapshot> getCommentsForPost(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Toggle OK reaction (like/unlike)
  Future<bool> toggleOkReaction(String postId) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the current post document
      DocumentSnapshot postDoc =
          await _firestore.collection('posts').doc(postId).get();

      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
      List<dynamic> okReactions = postData['okReactions'] ?? [];

      // Check if user has already reacted
      bool hasReacted = okReactions.contains(currentUser.uid);

      if (hasReacted) {
        // Remove reaction
        await _firestore.collection('posts').doc(postId).update({
          'okReactions': FieldValue.arrayRemove([currentUser.uid]),
          'okCount': FieldValue.increment(-1),
        });
        return false; // Reaction removed
      } else {
        // Add reaction
        await _firestore.collection('posts').doc(postId).update({
          'okReactions': FieldValue.arrayUnion([currentUser.uid]),
          'okCount': FieldValue.increment(1),
        });
        return true; // Reaction added
      }
    } catch (e) {
      throw Exception('Failed to toggle reaction: $e');
    }
  }

  // Delete a post and all its comments
  Future<void> deletePost(String postId) async {
    try {
      // Get all comments for the post
      QuerySnapshot commentsSnapshot =
          await _firestore
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .get();

      // Use a batch to delete all comments and the post
      WriteBatch batch = _firestore.batch();

      // Delete all comments
      for (DocumentSnapshot commentDoc in commentsSnapshot.docs) {
        batch.delete(commentDoc.reference);
      }

      // Delete the post
      batch.delete(_firestore.collection('posts').doc(postId));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }
}
