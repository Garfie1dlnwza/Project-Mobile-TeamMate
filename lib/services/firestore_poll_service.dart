import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createPoll({
    required String projectId,
    required String departmentId,
    required String question,
    required List<String> options,
    DateTime? endDate,
  }) async {
    try {
      DocumentReference pollRef = await _firestore.collection('polls').add({
        'projectId': projectId,
        'departmentId': departmentId,
        'question': question,
        'options': options,
        'createdAt': FieldValue.serverTimestamp(),
        'endDate': endDate ?? FieldValue.serverTimestamp(),
        'votes': {},
        'isActive': true,
      });

      // Update the department document to include the new poll ID
      await _firestore.collection('departments').doc(departmentId).update({
        'polls': FieldValue.arrayUnion([pollRef.id]),
      });

      return pollRef.id;
    } catch (e) {
      print('Error creating poll: $e');
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
}
