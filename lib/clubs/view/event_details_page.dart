import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/clubs/model/event.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync/powersync.dart' as psync;
import 'package:provider/provider.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage({
    required this.eventId,
    super.key,
  });

  final String eventId;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late TextEditingController _eventNameController;
  late TextEditingController _eventDescriptionController;
  late TextEditingController _eventDateController;
  DateTime? _selectedDate;
  late TextEditingController _eventTimeController;
  TimeOfDay? _selectedTime;
  late TextEditingController _eventTypeController;
  late TextEditingController _eventLocationController;
  late TextEditingController _eventFeesController;
  late TextEditingController _eventTeamsizeController;
  late TextEditingController _eventPosterimageController;
  late TextEditingController _contact1NameController;
  late TextEditingController _contact1PhnController;
  late TextEditingController _contact1RoleController;
  late TextEditingController _contact2NameController;
  late TextEditingController _contact2PhnController;
  late TextEditingController _contact2RoleController;
  late TextEditingController _registrationUrlController;

  Event? _event;
  late Future<List<Event>> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController();
    _eventDescriptionController = TextEditingController();
    _eventDateController = TextEditingController();
    _eventTimeController = TextEditingController();
    _eventTypeController = TextEditingController();
    _eventLocationController = TextEditingController();
    _eventFeesController = TextEditingController();
    _eventTeamsizeController = TextEditingController();
    _eventPosterimageController = TextEditingController();
    _contact1NameController = TextEditingController();
    _contact1PhnController = TextEditingController();
    _contact1RoleController = TextEditingController();
    _contact2NameController = TextEditingController();
    _contact2PhnController = TextEditingController();
    _contact2RoleController = TextEditingController();
    _registrationUrlController = TextEditingController();
    _eventFuture = _getEvent();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _eventDateController.dispose();
    _eventTypeController.dispose();
    _eventLocationController.dispose();
    _eventFeesController.dispose();
    _eventTeamsizeController.dispose();
    _eventPosterimageController.dispose();
    _contact1NameController.dispose();
    _contact1PhnController.dispose();
    _contact1RoleController.dispose();
    _contact2NameController.dispose();
    _contact2PhnController.dispose();
    _contact2RoleController.dispose();
    _registrationUrlController.dispose();
    super.dispose();
  }

  void _populateControllers(Event event) {
    _eventNameController.text = event.eventName;
    _eventDescriptionController.text = event.eventDescription;
    _eventDateController.text = event.eventDate;
    _selectedDate = DateTime.tryParse(event.eventDate);
    _eventTimeController.text = event.eventTime;
    _selectedTime = _parseTimeOfDay(event.eventTime);
    _eventTypeController.text = event.eventType;
    _eventLocationController.text = event.eventLocation;
    _eventFeesController.text = event.eventFees.toString();
    _eventTeamsizeController.text = event.eventTeamsize.toString();
    _eventPosterimageController.text = event.eventPosterimage;
    _contact1NameController.text = event.contact1Name;
    _contact1PhnController.text = event.contact1Phn;
    _contact1RoleController.text = event.contact1Role;
    _contact2NameController.text = event.contact2Name;
    _contact2PhnController.text = event.contact2Phn;
    _contact2RoleController.text = event.contact2Role;
    _registrationUrlController.text = event.registrationUrl;
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  Future<List<Event>> _getEvent() async {
    final databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
    final database = databaseClient.database;
    final rows = await database.getAll(
      'SELECT id, club_id, event_name, event_description, event_date, event_time, event_type, event_location, event_fees, event_teamsize, event_posterimage, contact1_name, contact1_phn, contact1_role, contact2_name, contact2_phn, contact2_role, registration_url FROM events WHERE id = ?',
      [widget.eventId],
    );
    return rows
        .map((row) => Event.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveEvent() async {
    final databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
    final database = databaseClient.database;

    await database.execute(
      '''
      UPDATE events SET
        event_name = ?,
        event_description = ?,
        event_date = ?,
        event_time = ?,
        event_type = ?,
        event_location = ?,
        event_fees = ?,
        event_teamsize = ?,
        event_posterimage = ?,
        contact1_name = ?,
        contact1_phn = ?,
        contact1_role = ?,
        contact2_name = ?,
        contact2_phn = ?,
        contact2_role = ?,
        registration_url = ?
      WHERE id = ?
      ''',
      [
        _eventNameController.text,
        _eventDescriptionController.text,
        _eventDateController.text,
        _eventTimeController.text,
        _eventTypeController.text,
        _eventLocationController.text,
        double.tryParse(_eventFeesController.text) ?? 0.0,
        int.tryParse(_eventTeamsizeController.text) ?? 0,
        _eventPosterimageController.text,
        _contact1NameController.text,
        _contact1PhnController.text,
        _contact1RoleController.text,
        _contact2NameController.text,
        _contact2PhnController.text,
        _contact2RoleController.text,
        _registrationUrlController.text,
        widget.eventId,
      ],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
      if (_event != null) {
        context.go('/clubs/${_event!.clubId}/manage_events');
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final databaseClient = Provider.of<PowerSyncDatabaseClient>(
        context,
        listen: false,
      );
      final database = databaseClient.database;

      await database.execute(
        'DELETE FROM events WHERE id = ?',
        [widget.eventId],
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/clubs/${_event?.clubId}/manage_events'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEvent,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: FutureBuilder<List<Event>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading event'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('Event not found'));
          }
          final event = events.first;
          if (_event == null) {
            _event = event;
            _populateControllers(event);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _eventNameController,
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.event),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _eventDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                GestureDetector(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                        _eventDateController.text =
                            '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _eventDateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFF181A26),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime ?? TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedTime = pickedTime;
                        _eventTimeController.text =
                            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _eventTimeController,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFF181A26),
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _eventTypeController,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _eventLocationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _eventFeesController,
                  decoration: InputDecoration(
                    labelText: 'Fees',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _eventTeamsizeController,
                  decoration: InputDecoration(
                    labelText: 'Team Size',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.group),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _eventPosterimageController,
                  decoration: InputDecoration(
                    labelText: 'Poster Image URL',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.image),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Contact 1'),
                const SizedBox(height: 14),
                TextField(
                  controller: _contact1NameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contact1PhnController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contact1RoleController,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Contact 2'),
                const SizedBox(height: 14),
                TextField(
                  controller: _contact2NameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contact2PhnController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contact2RoleController,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _registrationUrlController,
                  decoration: InputDecoration(
                    labelText: 'Registration URL',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF181A26),
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
