class CommentModel {
  final String commentId;
  final String assignmentId;
  final String userId;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.assignmentId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'assignmentId': assignmentId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      commentId: map['commentId'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
