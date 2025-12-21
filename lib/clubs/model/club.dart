class Club {
  const Club({
    required this.id,
    required this.clubName,
    required this.clubLogo,
    required this.clubDescription,
    required this.presidentName,
    required this.presidentImage,
    required this.vicePresidentName,
    required this.vicePresidentImage,
    required this.clubEmail,
  });

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'] as String,
      clubName: map['club_name'] as String,
      clubLogo: map['club_logo'] as String,
      clubDescription: map['club_description'] as String? ?? '',
      presidentName: map['president_name'] as String? ?? '',
      presidentImage: map['president_image'] as String? ?? '',
      vicePresidentName: map['vicepresident_name'] as String? ?? '',
      vicePresidentImage: map['vicepresident_image'] as String? ?? '',
      clubEmail: map['club_email'] as String? ?? '',
    );
  }

  final String id;
  final String clubName;
  final String clubLogo;
  final String clubDescription;
  final String presidentName;
  final String presidentImage;
  final String vicePresidentName;
  final String vicePresidentImage;
  final String clubEmail;
}
