import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProjectService {
  final CollectionReference _projectsCollection = 
      FirebaseFirestore.instance.collection('projects');

  // Create a new project
  Future<DocumentReference> createProject(Map<String, dynamic> projectData) async {
    return await _projectsCollection.add(projectData);
  }

  // Get a stream of all projects
  Stream<QuerySnapshot> getProjectsStream() {
    return _projectsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get a specific project by ID
  Future<DocumentSnapshot> getProjectById(String projectId) async {
    return await _projectsCollection.doc(projectId).get();
  }

  // Update project information
  Future<void> updateProject(String projectId, Map<String, dynamic> projectData) async {
    await _projectsCollection.doc(projectId).update(projectData);
  }

  // Delete a project
  Future<void> deleteProject(String projectId) async {
    await _projectsCollection.doc(projectId).delete();
  }

  // Add a task to a project
  Future<void> addTaskToProject(String projectId, String taskId) async {
    await _projectsCollection.doc(projectId).update({
      'tasks': FieldValue.arrayUnion([taskId])
    });
  }

  // Remove a task from a project
  Future<void> removeTaskFromProject(String projectId, String taskId) async {
    await _projectsCollection.doc(projectId).update({
      'tasks': FieldValue.arrayRemove([taskId])
    });
  }

  // Add a department to a project
  Future<void> addDepartmentToProject(String projectId, String department) async {
    await _projectsCollection.doc(projectId).update({
      'departments': FieldValue.arrayUnion([department])
    });
  }

  // Remove a department from a project
  Future<void> removeDepartmentFromProject(String projectId, String department) async {
    await _projectsCollection.doc(projectId).update({
      'departments': FieldValue.arrayRemove([department])
    });
  }

  // Add an admin to a project
  Future<void> addAdminToProject(String projectId, String userId) async {
    await _projectsCollection.doc(projectId).update({
      'admins': FieldValue.arrayUnion([userId])
    });
  }

  // Remove an admin from a project
  Future<void> removeAdminFromProject(String projectId, String userId) async {
    await _projectsCollection.doc(projectId).update({
      'admins': FieldValue.arrayRemove([userId])
    });
  }

  // Add a poll to a project
  Future<void> addPollToProject(String projectId, String pollId) async {
    await _projectsCollection.doc(projectId).update({
      'polls': FieldValue.arrayUnion([pollId])
    });
  }

  // Add a document to a project
  Future<void> addDocumentToProject(String projectId, String documentId) async {
    await _projectsCollection.doc(projectId).update({
      'documents': FieldValue.arrayUnion([documentId])
    });
  }

  // Check if user is admin of a project
  Future<bool> isUserAdminOfProject(String projectId, String userId) async {
    DocumentSnapshot projectDoc = await _projectsCollection.doc(projectId).get();
    Map<String, dynamic> data = projectDoc.data() as Map<String, dynamic>;
    List<dynamic> admins = data['admins'] ?? [];
    return admins.contains(userId);
  }
}