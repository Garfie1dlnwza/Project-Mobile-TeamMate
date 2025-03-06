class AttendanceModel {
  final String attendanceId;
  final String projectId;
  final String userId;
  final DateTime date;
  final String status; // เช่น "present", "absent", "late"

  AttendanceModel({
    required this.attendanceId,
    required this.projectId,
    required this.userId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'projectId': projectId,
      'userId': userId,
      'date': date.toIso8601String(),
      'status': status,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      attendanceId: map['attendanceId'] ?? '',
      projectId: map['projectId'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'absent',
    );
  }
}
