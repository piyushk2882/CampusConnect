import 'dart:developer';
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/app.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis/fcm/v1.dart' as fcm;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({
    required this.clubId,
    super.key,
  });

  final String clubId;

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventDateController = TextEditingController();
  DateTime? _selectedDate;
  final _eventTimeController = TextEditingController();
  TimeOfDay? _selectedTime;
  final _eventTypeController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _eventFeesController = TextEditingController();
  final _eventTeamsizeController = TextEditingController();
  final _contact1NameController = TextEditingController();
  final _contact1PhnController = TextEditingController();
  final _contact1RoleController = TextEditingController();
  final _contact2NameController = TextEditingController();
  final _contact2PhnController = TextEditingController();
  final _contact2RoleController = TextEditingController();
  final _registrationUrlController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _eventDateController.dispose();
    _eventTimeController.dispose();
    _eventTypeController.dispose();
    _eventLocationController.dispose();
    _eventFeesController.dispose();
    _eventTeamsizeController.dispose();
    _contact1NameController.dispose();
    _contact1PhnController.dispose();
    _contact1RoleController.dispose();
    _contact2NameController.dispose();
    _contact2PhnController.dispose();
    _contact2RoleController.dispose();
    _registrationUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final details = await PickImage().pickImage(context);
    if (details != null && details.selectedFiles.isNotEmpty) {
      setState(() {
        _selectedImage = details.selectedFiles.first.selectedFile;
      });
    }
  }

  Future<void> _selectDate() async {
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
  }

  Future<void> _selectTime() async {
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
  }

  Future<void> _sendEventNotification(String clubId, String eventName) async {
    try {
      final databaseClient = Provider.of<PowerSyncDatabaseClient>(
        context,
        listen: false,
      );
      final database = databaseClient.database;

      // Get club name
      final clubResult = await database.execute(
        'SELECT club_name FROM clubs WHERE id = ?',
        [clubId],
      );
      final clubName = clubResult.first['club_name'] as String;

      // Get all users with push tokens
      final usersResult = await database.execute(
        "SELECT push_token FROM profiles WHERE push_token IS NOT NULL AND push_token != ''",
      );

      final pushTokens = usersResult
          .map((row) => row['push_token'] as String)
          .toList();

      if (pushTokens.isEmpty) {
        log('No push tokens found in database');
        return;
      }

      log('Found ${pushTokens.length} push tokens, sending notifications...');

      // Use Firebase Cloud Messaging API (V1)
      // You'll need to set up a service account and get the credentials
      final serviceAccountJson = await rootBundle.loadString(
        'assets/campusconnect-dev-9473c-firebase-adminsdk-fbsvc-2d676927c9.json',
      );
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );
      final client = await auth.clientViaServiceAccount(accountCredentials, [
        'https://www.googleapis.com/auth/cloud-platform',
      ]);
      final fcmApi = fcm.FirebaseCloudMessagingApi(client);

      // Send notification to each token
      for (final token in pushTokens) {
        final message = fcm.Message(
          token: token,
          notification: fcm.Notification(
            title: 'Event Update',
            body: 'New event posted by $clubName: $eventName',
          ),
          data: {
            'type': 'event',
            'club_id': clubId,
            'event_name': eventName,
          },
        );

        final sendMessageRequest = fcm.SendMessageRequest(message: message);
        try {
          final response = await fcmApi.projects.messages.send(
            sendMessageRequest,
            'projects/campusconnect-dev-9473c',
          ); // Replace with your project ID

          log('Push notification sent successfully to token: ${token.substring(0, 10)}...');
                } catch (e) {
          logE('Error sending push notification to token: ${token.substring(0, 10)}...', error: e);
        }
      }

      client.close();
    } catch (e) {
      logE('Error sending event notification', error: e);
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final eventId = const Uuid().v4();
      final storage = Supabase.instance.client.storage.from('events');
      final fileName = '${eventId}_poster.${image.path.split('.').last}';
      final bytes = await image.readAsBytes();

      await storage.uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/${image.path.split('.').last}',
          cacheControl: '9000000',
        ),
      );

      final publicUrl = storage.getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      logE('Failed to upload image', error: e);
      return null;
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final databaseClient = Provider.of<PowerSyncDatabaseClient>(
        context,
        listen: false,
      );
      final database = databaseClient.database;

      String? posterUrl;
      if (_selectedImage != null) {
        posterUrl = await _uploadImage(_selectedImage!);
      }

      final eventId = const Uuid().v4();
      final eventData = {
        'id': eventId,
        'club_id': widget.clubId,
        'event_name': _eventNameController.text.trim(),
        'event_description': _eventDescriptionController.text.trim(),
        'event_date': _eventDateController.text.trim(),
        'event_time': _eventTimeController.text.trim(),
        'event_type': _eventTypeController.text.trim(),
        'event_location': _eventLocationController.text.trim(),
        'event_fees': double.tryParse(_eventFeesController.text) ?? 0.0,
        'event_teamsize': int.tryParse(_eventTeamsizeController.text) ?? 1,
        'event_posterimage': posterUrl ?? '',
        'contact1_name': _contact1NameController.text.trim(),
        'contact1_phn': _contact1PhnController.text.trim(),
        'contact1_role': _contact1RoleController.text.trim(),
        'contact2_name': _contact2NameController.text.trim(),
        'contact2_phn': _contact2PhnController.text.trim(),
        'contact2_role': _contact2RoleController.text.trim(),
        'registration_url': _registrationUrlController.text.trim(),
      };

      await database.execute(
        '''
        INSERT INTO events (
          id, club_id, event_name, event_description, event_date, event_type,
          event_location, event_fees, event_teamsize, event_posterimage,
          contact1_name, contact1_phn, contact1_role, contact2_name,
          contact2_phn, contact2_role, registration_url, event_time
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          eventData['id'],
          eventData['club_id'],
          eventData['event_name'],
          eventData['event_description'],
          eventData['event_date'],
          eventData['event_type'],
          eventData['event_location'],
          eventData['event_fees'],
          eventData['event_teamsize'],
          eventData['event_posterimage'],
          eventData['contact1_name'],
          eventData['contact1_phn'],
          eventData['contact1_role'],
          eventData['contact2_name'],
          eventData['contact2_phn'],
          eventData['contact2_role'],
          eventData['registration_url'],
          eventData['event_time'],
        ],
      );

      // Send push notifications after successful event creation
      log('Event created successfully, attempting to send push notifications...');
      await _sendEventNotification(
        widget.clubId,
        _eventNameController.text.trim(),
      );

      if (mounted) {
        context.pop();
        openSnackBar(
          const SnackbarMessage.success(title: 'Event created successfully'),
        );
      }
    } catch (e) {
      logE('Failed to create event', error: e);
      if (mounted) {
        openSnackBar(
          const SnackbarMessage.error(title: 'Failed to create event'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Poster Image Picker
              const Text(
                'Event Poster',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF181A26)),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF181A26),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48),
                            SizedBox(height: 8),
                            Text('Tap to select image'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Event Name
              TextFormField(
                controller: _eventNameController,
                decoration: InputDecoration(
                  labelText: 'Event Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Description
              TextFormField(
                controller: _eventDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Event Description',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Date
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _eventDateController,
                    decoration: InputDecoration(
                      labelText: 'Event Date (YYYY-MM-DD)',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: const Color(0xFF181A26),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select event date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Event Time
              GestureDetector(
                onTap: _selectTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _eventTimeController,
                    decoration: InputDecoration(
                      labelText: 'Event Time (HH:MM)',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: const Color(0xFF181A26),
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select event time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Event Type
              TextFormField(
                controller: _eventTypeController,
                decoration: InputDecoration(
                  labelText: 'Event Type',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Location
              TextFormField(
                controller: _eventLocationController,
                decoration: InputDecoration(
                  labelText: 'Event Location',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Fees
              TextFormField(
                controller: _eventFeesController,
                decoration: InputDecoration(
                  labelText: 'Event Fees',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 16),

              // Event Team Size
              TextFormField(
                controller: _eventTeamsizeController,
                decoration: InputDecoration(
                  labelText: 'Team Size',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.group),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Contact 1
              const Text(
                'Contact 1',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contact1NameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contact1PhnController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contact1RoleController,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.work),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
              ),
              const SizedBox(height: 16),

              // Contact 2
              const Text(
                'Contact 2',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contact2NameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contact2PhnController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contact2RoleController,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.work),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
              ),
              const SizedBox(height: 16),

              // Registration URL
              TextFormField(
                controller: _registrationUrlController,
                decoration: InputDecoration(
                  labelText: 'Registration URL',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              // Create Event Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF6EED2),
                      const Color(0xFFF6EED2).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF6EED2).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Create Event',
                          style: TextStyle(color: Colors.black),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
