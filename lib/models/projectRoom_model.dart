class ProjectModel {
  final String projectId;
  final String projectName;
  final String projectDescription;
  final DateTime startDate;
  final DateTime endDate;
  final String headId; // UID ของผู้สร้างโปรเจค (หัวหน้า)
  final List<String> employees; // รายชื่อพนักงานที่อยู่ในโปรเจค
  final String projectCode; // รหัสโปรเจค

  ProjectModel({
    required this.projectId,
    required this.projectName,
    required this.projectDescription,
    required this.startDate,
    required this.endDate,
    required this.headId,
    required this.employees,
    required this.projectCode,
  });

  // แปลงเป็น Map<String, dynamic> เพื่อใช้กับ Firebase หรือฐานข้อมูลอื่น ๆ
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'projectDescription': projectDescription,
      'startDate': startDate.toIso8601String(), // แปลงเป็น String
      'endDate': endDate.toIso8601String(), // แปลงเป็น String
      'headId': headId,
      'employees': employees,
      'projectCode': projectCode,
    };
  }

  // สร้างอ็อบเจ็กต์จาก Map<String, dynamic>
  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      projectId: map['projectId'] ?? '',
      projectName: map['projectName'] ?? '',
      projectDescription: map['projectDescription'] ?? '',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(), // แปลงเป็น DateTime
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(), // แปลงเป็น DateTime
      headId: map['headId'] ?? '',
      employees: List<String>.from(map['employees'] ?? []),
      projectCode: map['projectCode'] ?? '',
    );
  }
}
