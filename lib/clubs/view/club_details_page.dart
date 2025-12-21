import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/app.dart';
import 'package:campusconnect/clubs/clubs.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync/powersync.dart' as psync;
import 'package:provider/provider.dart';

enum _ViewMode { events, hiring }

class ClubDetailsPage extends StatefulWidget {
  const ClubDetailsPage({
    required this.clubId,
    super.key,
  });

  final String clubId;

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubDetailsPageState extends State<ClubDetailsPage> {
  _ViewMode _viewMode = _ViewMode.events;

  List<String> _parsePgArray(dynamic value) {
    if (value is List<dynamic>) {
      return value.cast<String>();
    } else if (value is String) {
      // Check if it's already a JSON array string like ["item1","item2"]
      if (value.startsWith('[') && value.endsWith(']')) {
        // Remove brackets and quotes, split by comma
        final content = value.substring(1, value.length - 1);
        if (content.isEmpty) return [];
        return content
            .split('","')
            .map((e) => e.replaceAll('"', '').trim())
            .toList();
      } else if (value.startsWith('{') && value.endsWith('}')) {
        final content = value.substring(1, value.length - 1);
        if (content.isEmpty) return [];
        return content.split(',').map((e) => e.trim()).map((e) {
          if (e.startsWith('"') && e.endsWith('"')) {
            return e
                .substring(1, e.length - 1)
                .replaceAll(r'\"', '"')
                .replaceAll(r'\\', r'\');
          }
          return e.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
        }).toList();
      }
      return [];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
    final database = databaseClient.database;
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Club Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<Club>>(
        stream: _watchClub(database, widget.clubId),
        builder: (context, clubSnapshot) {
          if (clubSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final clubs = clubSnapshot.data ?? [];
          if (clubs.isEmpty) {
            return const Center(child: Text('Club not found'));
          }
          final club = clubs.first;
          return StreamBuilder<List<Event>>(
            stream: _watchEvents(database, widget.clubId),
            builder: (context, eventSnapshot) {
              if (eventSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = eventSnapshot.data ?? [];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Club Logo
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: club.clubLogo.isNotEmpty
                          ? NetworkImage(club.clubLogo)
                          : null,
                      child: club.clubLogo.isEmpty
                          ? Icon(
                              Icons.groups,
                              size: 80,
                              color: Colors.grey.shade400,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Club Name
                    Text(
                      club.clubName,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Club Description
                    Text(
                      club.clubDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // President and VP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MemberCard(
                          image: club.presidentImage,
                          name: club.presidentName,
                          title: 'President',
                        ),
                        const SizedBox(width: 60),
                        _MemberCard(
                          image: club.vicePresidentImage,
                          name: club.vicePresidentName,
                          title: 'Vice President',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Toggle between Events and Hiring
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _viewMode = _ViewMode.events),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _viewMode == _ViewMode.events
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Club Events',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _viewMode == _ViewMode.events
                                          ? Theme.of(context).primaryColor
                                          : null,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _viewMode = _ViewMode.hiring),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _viewMode == _ViewMode.hiring
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Hiring',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _viewMode == _ViewMode.hiring
                                              ? Theme.of(context).primaryColor
                                              : null,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  StreamBuilder<Map<String, dynamic>?>(
                                    stream: databaseClient.watchClubHiring(
                                      widget.clubId,
                                    ),
                                    builder: (context, snapshot) {
                                      final hasHiring = snapshot.data != null;
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: hasHiring
                                              ? Colors.green
                                              : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final user = context.select(
                              (AppBloc bloc) => bloc.state.user,
                            );
                            if (user.email == club.clubEmail) {
                              return IconButton(
                                icon: const Icon(Icons.manage_accounts),
                                onPressed: () => context.go(
                                  _viewMode == _ViewMode.events
                                      ? '/clubs/${widget.clubId}/manage_events'
                                      : '/clubs/${widget.clubId}/manage_hiring',
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_viewMode == _ViewMode.events) ...[
                      if (events.isEmpty)
                        const Text('No events found')
                      else
                        Column(
                          children: events
                              .map((event) => _EventCard(event: event))
                              .toList(),
                        ),
                    ] else ...[
                      StreamBuilder<Map<String, dynamic>?>(
                        stream: databaseClient.watchClubHiring(widget.clubId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final hiringData = snapshot.data;
                          if (hiringData == null) {
                            return const Center(
                              child: Text('No hiring opportunities available'),
                            );
                          }
                          final roles = hiringData['roles'] is List
                              ? List<String>.from(
                                  hiringData['roles'] as Iterable<dynamic>,
                                )
                              : _parsePgArray(hiringData['roles']);
                          final classes = hiringData['classes'] is List
                              ? List<String>.from(
                                  hiringData['classes'] as Iterable<dynamic>,
                                )
                              : _parsePgArray(hiringData['classes']);
                          return _ClubHiringSection(
                            roles: roles,
                            classes: classes,
                            onApply: () =>
                                context.go('/clubs/${widget.clubId}/apply'),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<Club>> _watchClub(
    psync.PowerSyncDatabase database,
    String clubId,
  ) {
    return database
        .watch(
          'SELECT id, club_name, club_logo, club_description, president_name, president_image, vicepresident_name, vicepresident_image, club_email FROM clubs WHERE id = ?',
          parameters: [clubId],
        )
        .map(
          (rows) => rows
              .map((row) => Club.fromMap(row as Map<String, dynamic>))
              .toList(),
        );
  }

  Stream<List<Event>> _watchEvents(
    psync.PowerSyncDatabase database,
    String clubId,
  ) {
    return database
        .watch(
          'SELECT id, club_id, event_name, event_description, event_date, event_time, event_type, event_location, event_fees, event_teamsize, event_posterimage, contact1_name, contact1_phn, contact1_role, contact2_name, contact2_phn, contact2_role, registration_url FROM events WHERE club_id = ? ORDER BY event_date',
          parameters: [clubId],
        )
        .map(
          (rows) => rows
              .map((row) => Event.fromMap(row as Map<String, dynamic>))
              .toList(),
        );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.image,
    required this.name,
    required this.title,
  });

  final String image;
  final String name;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
          child: image.isEmpty
              ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/events/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF181A26),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.eventPosterimage.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    event.eventPosterimage,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  event.eventName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (event.eventDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.eventDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Date: ${event.eventDate}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Time: ${event.eventTime}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Location: ${event.eventLocation}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubHiringSection extends StatelessWidget {
  const _ClubHiringSection({
    required this.roles,
    required this.classes,
    required this.onApply,
  });

  final List<String> roles;
  final List<String> classes;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Available Roles',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles.map((role) => Chip(
                label: Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: const Color(0xFF181A26),
                elevation: 2,
                shadowColor: const Color(0xFF181A26).withOpacity(0.3),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Eligible Classes: ${classes.join(', ')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF6EED2),
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
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.send,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Apply Now',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
