class ClubHiring {
  const ClubHiring({
    required this.id,
    required this.clubId,
    required this.roles,
    required this.classes,
    required this.createdAt,
  });

  factory ClubHiring.fromMap(Map<String, dynamic> map) {
    return ClubHiring(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      roles: _parsePgArray(map['roles'] as String),
      classes: _parsePgArray(map['classes'] as String),
      createdAt: map['created_at'] as String,
    );
  }

  static List<String> _parsePgArray(dynamic value) {
    if (value is List<dynamic>) {
      return value.cast<String>();
    } else if (value is String) {
      if (value.startsWith('{') && value.endsWith('}')) {
        final content = value.substring(1, value.length - 1);
        if (content.isEmpty) return [];
        return content.split(',').map((e) => e.trim()).map((e) {
          if (e.startsWith('"') && e.endsWith('"')) {
            return e.substring(1, e.length - 1).replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
          }
          return e.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
        }).toList();
      }
      return [];
    }
    return [];
  }

  final String id;
  final String clubId;
  final List<String> roles;
  final List<String> classes;
  final String createdAt;
}
