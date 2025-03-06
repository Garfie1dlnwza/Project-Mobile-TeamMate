class SubmissionModel {
  final String summitId;
  final String assignmentId;
  final String employeeId;
  final String fileUrl;
  final DateTime submittedAt;
  final String status;

  SubmissionModel({
    required this.summitId,
    required this.assignmentId,
    required this.employeeId,
    required this.fileUrl,
    required this.submittedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'summitId': summitId,
      'assignmentId': assignmentId,
      'studentId': employeeId,
      'fileUrl': fileUrl,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
    };
  }

  factory SubmissionModel.fromMap(Map<String, dynamic> map) {
    return SubmissionModel(
      summitId: map['summitId'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      submittedAt: DateTime.parse(
        map['submittedAt'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'pending',
    );
  }
}
