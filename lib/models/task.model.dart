class TaskModel {
  final String taskId;
  final String assignmentId; // อ้างถึง Assignment ที่ Task นี้อยู่ในนั้น
  final String title;
  final String description;
  final String assignedTo; // userId ของพนักงานที่ได้รับ Task นี้
  final String status; // เช่น "pending", "in_progress", "completed"
  final DateTime dueDate;
  final DateTime createdAt;

  TaskModel({
    required this.taskId,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.status,
    required this.dueDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'assignmentId': assignmentId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'status': status,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      taskId: map['taskId'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      status: map['status'] ?? 'pending',
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
