class AssignmentModel {
  final String assignmentId;
  final String projectId;
  final String title;
  final String description;
  final DateTime dueDate;
  final String assignedBy;
  final List<String> submittedBy; //list คนส่งงาน

  AssignmentModel({
    required this.assignmentId,
    required this.projectId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedBy,

    required this.submittedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': assignmentId,
      'projectRoomId': projectId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'submittedBy': submittedBy,
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      assignmentId: map['assignmentId'] ?? '',
      projectId: map['projectRoomId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: DateTime.parse(
        map['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      assignedBy: map['assignedBy']??'',
      submittedBy: List<String>.from(map['submittedBy'] ?? []),
    );
  }
}
