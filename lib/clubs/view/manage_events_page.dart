import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/clubs/model/event.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync/powersync.dart' as psync;
import 'package:provider/provider.dart';

class ManageEventsPage extends StatelessWidget {
  const ManageEventsPage({
    required this.clubId,
    super.key,
  });

  final String clubId;

  @override
  Widget build(BuildContext context) {
    final databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
    final database = databaseClient.database;
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                context.go('/clubs/$clubId/manage_events/create_event'),
          ),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: _watchEvents(database, clubId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No events found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(event: event);
            },
          );
        },
      ),
    );
  }

  Stream<List<Event>> _watchEvents(
    psync.PowerSyncDatabase database,
    String clubId,
  ) {
    return database
        .watch(
          'SELECT id, club_id, event_name, event_description, event_date, event_type, event_location, event_fees, event_teamsize, event_posterimage, contact1_name, contact1_phn, contact1_role, contact2_name, contact2_phn, contact2_role, registration_url FROM events WHERE club_id = ? ORDER BY event_date',
          parameters: [clubId],
        )
        .map(
          (rows) => rows
              .map((row) => Event.fromMap(row as Map<String, dynamic>))
              .toList(),
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
    return Tappable(
      onTap: () => context.go('/events/${event.id}/edit'),
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
              Text(
                event.eventName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (event.eventDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.eventDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Date: ${event.eventDate}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(),
              ),
              if (event.eventLocation.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Location: ${event.eventLocation}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
