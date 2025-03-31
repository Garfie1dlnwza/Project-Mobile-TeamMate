import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestorePollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createPoll({
    required String projectId,
    required String departmentId,
    required String question,
    required List<String> options,
    DateTime? endDate,
  }) async {
    try {
      // Generate a unique poll ID
      String pollId = _firestore.collection('polls').doc().id;

      // Create a map to store votes for each option
      Map<String, List<String>> votesMap = {};
      for (String option in options) {
        votesMap[option] = [];
      }

      // Store poll data in Firestore with the generated pollId
      await _firestore.collection('polls').doc(pollId).set({
        'pollId': pollId, // Store pollId in the document
        'projectId': projectId,
        'departmentId': departmentId,
        'question': question,
        'options': options,
        'createdAt': FieldValue.serverTimestamp(),
        'endDate': endDate ?? FieldValue.serverTimestamp(),
        'votes': votesMap,
        'totalVotes': 0,
        'isActive': true,
      });

      // Update the department document to include the new poll ID
      await _firestore.collection('departments').doc(departmentId).update({
        'polls': FieldValue.arrayUnion([pollId]),
      });

      return pollId;
    } catch (e) {
      print('Error creating poll: $e');
      rethrow;
    }
  }

  Future<void> submitVote(String pollId, String selectedOption) async {
    try {
      // Get current user ID
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get the current poll data
      DocumentSnapshot pollDoc =
          await _firestore.collection('polls').doc(pollId).get();
      Map<String, dynamic> pollData = pollDoc.data() as Map<String, dynamic>;

      // Check if the poll is still active
      if (!(pollData['isActive'] ?? true)) {
        throw Exception('This poll is no longer active');
      }

      // Check if user has already voted by scanning all options
      bool alreadyVoted = false;
      String previousVote = '';
      Map<String, dynamic> votes = pollData['votes'] ?? {};

      for (var option in votes.keys) {
        List<dynamic> voters = votes[option] ?? [];
        if (voters.contains(userId)) {
          alreadyVoted = true;
          previousVote = option;
          break;
        }
      }

      // Begin transaction
      return _firestore.runTransaction((transaction) async {
        // If user already voted, remove their previous vote
        if (alreadyVoted) {
          transaction.update(_firestore.collection('polls').doc(pollId), {
            'votes.$previousVote': FieldValue.arrayRemove([userId]),
          });
        } else {
          // Increment total votes only if this is a new vote
          transaction.update(_firestore.collection('polls').doc(pollId), {
            'totalVotes': FieldValue.increment(1),
          });
        }

        // Add the new vote
        transaction.update(_firestore.collection('polls').doc(pollId), {
          'votes.$selectedOption': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (e) {
      print('Error submitting vote: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getPollbyDepartmentID(String departmentId) {
    try {
      return _firestore
          .collection('polls')
          .where('departmentId', isEqualTo: departmentId)
          .snapshots();
    } catch (e) {
      print('Error fetching polls: $e');
      rethrow;
    }
  }

  Stream<DocumentSnapshot> getPollById(String pollId) {
    try {
      return _firestore.collection('polls').doc(pollId).snapshots();
    } catch (e) {
      print('Error fetching poll: $e');
      rethrow;
    }
  }

  Future<bool> hasUserVoted(String pollId) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      DocumentSnapshot pollDoc =
          await _firestore.collection('polls').doc(pollId).get();
      Map<String, dynamic> pollData = pollDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> votes = pollData['votes'] ?? {};

      for (var option in votes.keys) {
        List<dynamic> voters = votes[option] ?? [];
        if (voters.contains(userId)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking if user voted: $e');
      return false;
    }
  }
}
