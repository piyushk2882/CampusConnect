import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/clubs/model/club.dart';
import 'package:campusconnect/clubs/model/event.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync/powersync.dart' as psync;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsViewPage extends StatelessWidget {
  const EventDetailsViewPage({
    required this.eventId,
    super.key,
  });

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
    final database = databaseClient.database;

    return StreamBuilder<List<Event>>(
      stream: _watchEvent(database, eventId),
      builder: (context, eventSnapshot) {
        if (eventSnapshot.connectionState == ConnectionState.waiting) {
          return AppScaffold(
            appBar: AppBar(
              title: const Text('Event Details'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final events = eventSnapshot.data ?? [];
        if (events.isEmpty) {
          return AppScaffold(
            appBar: AppBar(
              title: const Text('Event Details'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Text('Event not found')),
          );
        }
        final event = events.first;

        return AppScaffold(
          appBar: AppBar(
            title: const Text('Event Details'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/clubs/${event.clubId}'),
            ),
          ),
          body: StreamBuilder<List<Club>>(
            stream: _watchClub(database, event.clubId),
            builder: (context, clubSnapshot) {
              if (clubSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final clubs = clubSnapshot.data ?? [];
              final club = clubs.isNotEmpty ? clubs.first : null;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Event Poster
                    if (event.eventPosterimage.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showFullScreenImage(
                          context,
                          event.eventPosterimage,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(event.eventPosterimage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Event Info Section
                    Text(
                      '${event.eventTime} • ${event.eventLocation}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.eventName,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club?.clubName ?? 'Unknown Club',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Event Meta Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _MetaItem(
                            icon: Icons.currency_rupee,
                            label: 'Event Fee',
                            value: event.eventFees == 0
                                ? 'Free'
                                : '₹${event.eventFees}',
                          ),
                          _MetaItem(
                            icon: Icons.calendar_today,
                            label: 'Event Date',
                            value: event.eventDate,
                          ),
                          _MetaItem(
                            icon: Icons.group,
                            label: 'Team Size',
                            value: event.eventTeamsize.toString(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Event Description Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Details',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.eventDescription,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bottom Section: Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _launchRegistrationUrl(event.registrationUrl),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFF6EED2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Register Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Stream<List<Event>> _watchEvent(
    psync.PowerSyncDatabase database,
    String eventId,
  ) {
    return database
        .watch(
          'SELECT id, club_id, event_name, event_description, event_date, event_time, event_type, event_location, event_fees, event_teamsize, event_posterimage, contact1_name, contact1_phn, contact1_role, contact2_name, contact2_phn, contact2_role, registration_url FROM events WHERE id = ?',
          parameters: [eventId],
        )
        .map(
          (rows) => rows
              .map((row) => Event.fromMap(row as Map<String, dynamic>))
              .toList(),
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => context.pop(),
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  Future<void> _launchRegistrationUrl(String url) async {
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFFF6EED2)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
