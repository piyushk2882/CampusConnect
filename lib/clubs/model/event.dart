class Event {
  const Event({
    required this.id,
    required this.clubId,
    required this.eventName,
    required this.eventDescription,
    required this.eventDate,
    required this.eventTime,
    required this.eventType,
    required this.eventLocation,
    required this.eventFees,
    required this.eventTeamsize,
    required this.eventPosterimage,
    required this.contact1Name,
    required this.contact1Phn,
    required this.contact1Role,
    required this.contact2Name,
    required this.contact2Phn,
    required this.contact2Role,
    required this.registrationUrl,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      eventName: map['event_name'] as String,
      eventDescription: map['event_description'] as String? ?? '',
      eventDate: map['event_date'] as String? ?? '',
      eventTime: map['event_time'] as String? ?? '',
      eventType: map['event_type'] as String? ?? '',
      eventLocation: map['event_location'] as String? ?? '',
      eventFees: map['event_fees'] as double? ?? 0.0,
      eventTeamsize: map['event_teamsize'] as int? ?? 0,
      eventPosterimage: map['event_posterimage'] as String? ?? '',
      contact1Name: map['contact1_name'] as String? ?? '',
      contact1Phn: map['contact1_phn'] as String? ?? '',
      contact1Role: map['contact1_role'] as String? ?? '',
      contact2Name: map['contact2_name'] as String? ?? '',
      contact2Phn: map['contact2_phn'] as String? ?? '',
      contact2Role: map['contact2_role'] as String? ?? '',
      registrationUrl: map['registration_url'] as String? ?? '',
    );
  }

  final String id;
  final String clubId;
  final String eventName;
  final String eventDescription;
  final String eventDate;
  final String eventTime;
  final String eventType;
  final String eventLocation;
  final double eventFees;
  final int eventTeamsize;
  final String eventPosterimage;
  final String contact1Name;
  final String contact1Phn;
  final String contact1Role;
  final String contact2Name;
  final String contact2Phn;
  final String contact2Role;
  final String registrationUrl;
}
