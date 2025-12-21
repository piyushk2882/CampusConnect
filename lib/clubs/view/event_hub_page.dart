import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:async/async.dart';
import 'package:campusconnect/clubs/clubs.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync/powersync.dart' as psync;
import 'package:provider/provider.dart';

class Debouncer {

  Debouncer({required this.milliseconds});
  final int milliseconds;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class EventHubPage extends StatefulWidget {
  const EventHubPage({super.key});

  @override
  State<EventHubPage> createState() => _EventHubPageState();
}

class _EventHubPageState extends State<EventHubPage> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  String _selectedClub = 'All Clubs';
  List<Club> _clubs = [];
  List<Event> _events = [];
  List<Event> _filteredEvents = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debouncer.run(_filterEvents);
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _events.where((event) {
        final matchesSearch =
            event.eventName.toLowerCase().contains(query) ||
            event.eventDescription.toLowerCase().contains(query);
        final matchesClub =
            _selectedClub == 'All Clubs' ||
            _clubs.any(
              (club) =>
                  club.id == event.clubId && club.clubName == _selectedClub,
            );
        return matchesSearch && matchesClub;
      }).toList();
    });
  }

  void _onClubChanged(String? newValue) {
    setState(() {
      _selectedClub = newValue ?? 'All Clubs';
      _filterEvents();
    });
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
        title: const Text('Event Hub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _watchEventsAndClubs(database),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? [];
          _events = data.whereType<Event>().toList();
          _clubs = data.whereType<Club>().toList();
          if (_filteredEvents.isEmpty &&
              _searchController.text.isEmpty &&
              _selectedClub == 'All Clubs') {
            _filteredEvents = _events;
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedClub,
                      items:
                          (['All Clubs'] +
                                  _clubs.map((club) => club.clubName).toList())
                              .map(
                                (clubName) => DropdownMenuItem<String>(
                                  value: clubName,
                                  child: Text(clubName),
                                ),
                              )
                              .toList(),
                      onChanged: _onClubChanged,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredEvents.isEmpty
                    ? const Center(child: Text('No events found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = _filteredEvents[index];
                          final club = _clubs.firstWhere(
                            (c) => c.id == event.clubId,
                            orElse: () => Club(
                              id: '',
                              clubName: 'Unknown Club',
                              clubLogo: '',
                              clubDescription: '',
                              presidentName: '',
                              presidentImage: '',
                              vicePresidentName: '',
                              vicePresidentImage: '',
                              clubEmail: '',
                            ),
                          );
                          return _EventCard(event: event, club: club);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Stream<List<dynamic>> _watchEventsAndClubs(psync.PowerSyncDatabase database) {
    final eventsStream = database
        .watch(
          'SELECT id, club_id, event_name, event_description, event_date, event_time, event_type, event_location, event_fees, event_teamsize, event_posterimage, contact1_name, contact1_phn, contact1_role, contact2_name, contact2_phn, contact2_role, registration_url FROM events ORDER BY event_date',
        )
        .map(
          (rows) => rows
              .map((row) => Event.fromMap(row as Map<String, dynamic>))
              .toList(),
        );

    final clubsStream = database
        .watch(
          'SELECT id, club_name, club_logo, club_description, president_name, president_image, vicepresident_name, vicepresident_image, club_email FROM clubs',
        )
        .map(
          (rows) => rows
              .map((row) => Club.fromMap(row as Map<String, dynamic>))
              .toList(),
        );

    return StreamZip([
      eventsStream,
      clubsStream,
    ]).map((values) => [...values[0], ...values[1]]);
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.club,
  });

  final Event event;
  final Club club;

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
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'by ${club.clubName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
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
