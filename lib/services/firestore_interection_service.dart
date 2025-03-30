import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a comment to a content item (post, poll, task)
  Future<String?> addComment({
    required String contentId,
    required String contentType, // 'post', 'poll', 'task'
    required String comment,
  }) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create a comment document
      DocumentReference commentRef =
          _firestore
              .collection('${contentType}s')
              .doc(contentId)
              .collection('comments')
              .doc();

      // Prepare comment data
      Map<String, dynamic> commentData = {
        'commentId': commentRef.id,
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous User',
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save comment to Firestore
      await commentRef.set(commentData);

      // Update comment count in the parent document
      await _firestore.collection('${contentType}s').doc(contentId).update({
        'commentCount': FieldValue.increment(1),
      });

      return commentRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  // Get comments for a specific content item
  Stream<QuerySnapshot> getComments(String contentId, String contentType) {
    return _firestore
        .collection('${contentType}s')
        .doc(contentId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Toggle OK reaction (like/unlike functionality)
  Future<bool> toggleOkReaction({
    required String contentId,
    required String contentType, // 'post', 'poll', 'task'
  }) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Reference to the content document
      DocumentReference contentRef = _firestore
          .collection('${contentType}s')
          .doc(contentId);

      // Get the current document to check if user already reacted
      DocumentSnapshot contentDoc = await contentRef.get();

      if (!contentDoc.exists) {
        throw Exception('Content not found');
      }

      Map<String, dynamic> contentData =
          contentDoc.data() as Map<String, dynamic>;
      List<String> okReactions = List<String>.from(
        contentData['okReactions'] ?? [],
      );

      bool hasReacted = okReactions.contains(currentUser.uid);

      // Toggle reaction
      if (hasReacted) {
        // Remove reaction
        await contentRef.update({
          'okReactions': FieldValue.arrayRemove([currentUser.uid]),
          'okCount': FieldValue.increment(-1),
        });
        return false; // User removed reaction
      } else {
        // Add reaction
        await contentRef.update({
          'okReactions': FieldValue.arrayUnion([currentUser.uid]),
          'okCount': FieldValue.increment(1),
        });
        return true; // User added reaction
      }
    } catch (e) {
      print('Error toggling OK reaction: $e');
      rethrow;
    }
  }

  // Check if user has reacted with OK to a content item
  Future<bool> hasUserReactedOk({
    required String contentId,
    required String contentType,
  }) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      // Get the content document
      DocumentSnapshot contentDoc =
          await _firestore.collection('${contentType}s').doc(contentId).get();

      if (!contentDoc.exists) {
        return false;
      }

      Map<String, dynamic> contentData =
          contentDoc.data() as Map<String, dynamic>;
      List<dynamic> okReactions = contentData['okReactions'] ?? [];

      return okReactions.contains(currentUser.uid);
    } catch (e) {
      print('Error checking if user reacted OK: $e');
      return false;
    }
  }

  // Get OK reaction count for a content item
  Future<int> getOkReactionCount({
    required String contentId,
    required String contentType,
  }) async {
    try {
      DocumentSnapshot contentDoc =
          await _firestore.collection('${contentType}s').doc(contentId).get();

      if (!contentDoc.exists) {
        return 0;
      }

      Map<String, dynamic> contentData =
          contentDoc.data() as Map<String, dynamic>;

      // If okCount field exists, use it; otherwise count the array length
      if (contentData.containsKey('okCount')) {
        return contentData['okCount'] ?? 0;
      } else {
        List<dynamic> okReactions = contentData['okReactions'] ?? [];
        return okReactions.length;
      }
    } catch (e) {
      print('Error getting OK reaction count: $e');
      return 0;
    }
  }
}
