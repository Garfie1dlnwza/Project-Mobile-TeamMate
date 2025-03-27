import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProjectService {
  final CollectionReference _projectsCollection = FirebaseFirestore.instance
      .collection('projects');

  // สร้างโปรเจคใหม่ใน Firestore
  Future<String> createProject(Map<String, dynamic> projectData) async {
    try {
      DocumentReference docRef = await _projectsCollection.add(projectData);
      return docRef.id;
    } catch (e) {
      print("Error creating project: $e");
      rethrow;
    }
  }

  // ดึงสตรีมของโปรเจคสำหรับผู้ใช้
  Stream<QuerySnapshot> getUserProjectsStream(List<String> projectIds) {
    if (projectIds.isEmpty) {
      return Stream.empty();
    }
    return _projectsCollection
        .where(FieldPath.documentId, whereIn: projectIds)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ดึงสตรีมของโปรเจคทั้งหมด
  Stream<QuerySnapshot> getProjectsStream() {
    return _projectsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ดึงโปรเจคเฉพาะโดย ID
  Future<DocumentSnapshot> getProjectById(String projectId) async {
    try {
      return await _projectsCollection.doc(projectId).get();
    } catch (e) {
      print("Error getting project by ID: $e");
      rethrow;
    }
  }

  // อัปเดตข้อมูลโปรเจค
  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> projectData,
  ) async {
    try {
      await _projectsCollection.doc(projectId).update(projectData);
    } catch (e) {
      print("Error updating project: $e");
      rethrow;
    }
  }

  // ลบโปรเจค
  Future<void> deleteProject(String projectId) async {
    try {
      await _projectsCollection.doc(projectId).delete();
    } catch (e) {
      print("Error deleting project: $e");
      rethrow;
    }
  }

  /// Removes a user from a project (when a user wants to leave a project)
  Future<void> removeUserFromProject(String projectId, String userId) async {
    try {
      // 1. Get the project to find all its departments
      DocumentSnapshot projectDoc =
          await _projectsCollection.doc(projectId).get();

      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      Map<String, dynamic>? projectData =
          projectDoc.data() as Map<String, dynamic>?;

      if (projectData == null) {
        throw Exception('Project data is null');
      }

      // 2. Get all the departments in this project
      List<dynamic> departmentIds = projectData['departments'] ?? [];

      // 3. For each department, remove the user
      for (String departmentId in List<String>.from(departmentIds)) {
        // Get reference to departments collection
        DocumentReference departmentRef = FirebaseFirestore.instance
            .collection('departments')
            .doc(departmentId);

        // Remove user from the users array in each department
        await departmentRef.update({
          'users': FieldValue.arrayRemove([userId]),
        });

        // Also remove from admins if they are an admin
        await departmentRef.update({
          'admins': FieldValue.arrayRemove([userId]),
        });

        print('Removed user $userId from department $departmentId');
      }

      // 4. Remove the project from the user's projects list
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'projectIds': FieldValue.arrayRemove([projectId]),
      });

      print('Removed project $projectId from user $userId');

      // 5. If the user is the head of the project, handle this special case
      dynamic headId = projectData['headId'];

      // Check if current user is the project head
      bool isHead = false;
      if (headId is String) {
        isHead = headId == userId;
      } else if (headId is List) {
        isHead = headId.contains(userId);
      }

      // If user is the project head, we have a special case to handle
      if (isHead) {
        // Option 1: Delete the project if no other users are in it
        // This would require checking all departments for remaining users

        // Option 2: Assign a new head (not implemented here)
        // For now, we'll just log that the project head has left
        print('Warning: Project head is leaving project $projectId');

        // If headId is a list and has multiple heads, just remove this user
        if (headId is List && headId.length > 1) {
          await _projectsCollection.doc(projectId).update({
            'headId': FieldValue.arrayRemove([userId]),
          });
        }
        // If this is the only head, we don't modify the headId field
        // to prevent orphaning the project
      }

      print('User $userId successfully removed from project $projectId');
    } catch (e) {
      print('Error removing user from project: $e');
      rethrow;
    }
  }

  /// Deletes a project and all associated data including departments and user references
  Future<void> deleteProjectCompletely(String projectId) async {
    try {
      // 1. Get project data
      DocumentSnapshot projectDoc = await getProjectById(projectId);
      Map<String, dynamic>? projectData =
          projectDoc.data() as Map<String, dynamic>?;

      if (projectData == null) {
        throw Exception('Project data not found');
      }

      // 2. Get all department IDs in this project
      List<dynamic> departmentIds = projectData['departments'] ?? [];

      // 3. Delete all departments associated with this project
      for (String departmentId in List<String>.from(departmentIds)) {
        // Delete the department document in Firestore
        await FirebaseFirestore.instance
            .collection('departments')
            .doc(departmentId)
            .delete();

        print('Department deleted: $departmentId');
      }

      // 4. Remove project reference from all users who have this project
      // Find all users who have this project
      QuerySnapshot usersWithProject =
          await FirebaseFirestore.instance
              .collection('users')
              .where('projectIds', arrayContains: projectId)
              .get();

      // Remove project from each user's projectIds array
      for (DocumentSnapshot userDoc in usersWithProject.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .update({
              'projectIds': FieldValue.arrayRemove([projectId]),
            });

        print('Project removed from user: ${userDoc.id}');
      }

      // 5. Delete other related data if necessary
      // For example, you might need to delete data from other collections that reference this project

      // 6. Finally delete the project document itself
      await deleteProject(projectId);
      print('Project deleted: $projectId');

      return;
    } catch (e) {
      print('Error in complete project deletion: $e');
      rethrow;
    }
  }

  // ดึงโปรเจคโดยใช้ department ID
  Future<DocumentSnapshot> getProjectByDepartmentId(String departmentId) async {
    try {
      // Query projects where the departments array contains the specified departmentId
      QuerySnapshot querySnapshot =
          await _projectsCollection
              .where('departments', arrayContains: departmentId)
              .limit(1)
              .get();
      // Check if we found any matching project
      if (querySnapshot.docs.isNotEmpty) {
        // Return the first matching project document
        return querySnapshot.docs.first;
      } else {
        throw Exception('No project found with department ID: $departmentId');
      }
    } catch (e) {
      print('Error in getProjectByDepartmentId: $e');
      rethrow;
    }
  }

  // ตรวจสอบว่า user เป็น head ของ project หรือไม่
  Future<bool> isUserHeadOfProject(String projectId, String userId) async {
    try {
      DocumentSnapshot projectDoc =
          await _projectsCollection.doc(projectId).get();
      if (!projectDoc.exists) {
        return false;
      }
      Map<String, dynamic>? data = projectDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        return false;
      }
      // Check if headId is a single string or a list
      dynamic headId = data['headId'];
      if (headId is String) {
        return headId == userId;
      } else if (headId is List) {
        return headId.contains(userId);
      }
      return false;
    } catch (e) {
      print("Error checking if user is head of project: $e");
      return false;
    }
  }
}
