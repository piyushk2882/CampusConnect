class ClubApplication {
  const ClubApplication({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.studentName,
    required this.class_,
    required this.department,
    required this.prn,
    required this.phone,
    required this.roleApplied,
    required this.resumeUrl,
    required this.status,
    required this.createdAt,
  });

  factory ClubApplication.fromMap(Map<String, dynamic> map) {
    return ClubApplication(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      userId: map['user_id'] as String,
      studentName: map['student_name'] as String,
      class_: map['class'] as String,
      department: map['department'] as String,
      prn: map['prn'] as String,
      phone: map['phone'] as String,
      roleApplied: map['role_applied'] as String,
      resumeUrl: map['resume_url'] as String,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  final String id;
  final String clubId;
  final String userId;
  final String studentName;
  final String class_;
  final String department;
  final String prn;
  final String phone;
  final String roleApplied;
  final String resumeUrl;
  final String status;
  final String createdAt;
}
