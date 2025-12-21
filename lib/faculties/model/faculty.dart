import 'package:equatable/equatable.dart';

class Faculty extends Equatable {
  const Faculty({
    required this.titleOfRespect,
    required this.fullname,
    required this.department,
    required this.designation,
    required this.mobileNo,
    required this.email,
    required this.photoUrl,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      titleOfRespect: json['title_of_respect'] as String,
      fullname: json['fullname'] as String,
      department: json['department'] as String,
      designation: json['designation'] as String,
      mobileNo: json['mobile_no'] as String,
      email: json['email'] as String,
      photoUrl: json['photo_url'] as String,
    );
  }

  final String titleOfRespect;
  final String fullname;
  final String department;
  final String designation;
  final String mobileNo;
  final String email;
  final String photoUrl;

  @override
  List<Object?> get props => [
        titleOfRespect,
        fullname,
        department,
        designation,
        mobileNo,
        email,
        photoUrl,
      ];

  Map<String, dynamic> toJson() {
    return {
      'title_of_respect': titleOfRespect,
      'fullname': fullname,
      'department': department,
      'designation': designation,
      'mobile_no': mobileNo,
      'email': email,
      'photo_url': photoUrl,
    };
  }
}
