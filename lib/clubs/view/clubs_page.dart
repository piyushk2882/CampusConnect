import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/clubs/clubs.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync/powersync.dart' as psync;
import 'package:provider/provider.dart';

class ClubsPage extends StatelessWidget {
  const ClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
    final database = databaseClient.database;
    return WillPopScope(
      onWillPop: () async {
        context.go('/feed');
        return false;
      },
      child: AppScaffold(
        appBar: AppBar(
          title: const Text(
            'Explore Clubs',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Colors.black,
                ],
              ),
            ),
          ),
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          child: StreamBuilder<List<Club>>(
            stream: _watchClubs(database),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.deepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading Clubs...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final clubs = snapshot.data ?? [];
              if (clubs.isEmpty) {
                // Insert sample data once after the frame is built
                SchedulerBinding.instance.addPostFrameCallback((_) async {
                  final dbClient = Provider.of<PowerSyncDatabaseClient>(
                    context,
                    listen: false,
                  );
                  final db = dbClient.database;
                  await db.execute(
                    'INSERT INTO clubs (club_name, club_logo, club_description, president_name, president_image, vicepresident_name, vicepresident_image, club_email) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                    [
                      'Photography Club',
                      '',
                      'Capture moments and share your passion for photography.',
                      'Alice Johnson',
                      '',
                      'Bob Smith',
                      '',
                      'photography@campus.edu',
                    ],
                  );
                  await db.execute(
                    'INSERT INTO clubs (club_name, club_logo, club_description, president_name, president_image, vicepresident_name, vicepresident_image, club_email) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                    [
                      'Debate Club',
                      '',
                      'Hone your argumentative skills and engage in lively debates.',
                      'Carol Davis',
                      '',
                      'David Wilson',
                      '',
                      'debate@campus.edu',
                    ],
                  );
                  await db.execute(
                    'INSERT INTO clubs (club_name, club_logo, club_description, president_name, president_image, vicepresident_name, vicepresident_image, club_email) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                    [
                      'Coding Club',
                      '',
                      'Build apps, solve problems, and code the future.',
                      'Eve Brown',
                      '',
                      'Frank Miller',
                      '',
                      'coding@campus.edu',
                    ],
                  );
                });
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.groups_outlined,
                          size: 80,
                          color: Colors.deepPurple.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Clubs Found',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New clubs will appear here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  // Trigger a refresh; PowerSync handles sync automatically
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: Colors.deepPurple,
                backgroundColor: Colors.white,
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: clubs.length,
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    return _ClubCard(club: club, index: index);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Stream<List<Club>> _watchClubs(psync.PowerSyncDatabase database) {
    return database
        .watch(
          'SELECT id, club_name, club_logo, club_description, president_name, president_image, vicepresident_name, vicepresident_image, club_email FROM clubs ORDER BY club_name',
        )
        .map(
          (rows) => rows
              .map((row) => Club.fromMap(row as Map<String, dynamic>))
              .toList(),
        );
  }
}

class _ClubCard extends StatefulWidget {
  const _ClubCard({
    required this.club,
    required this.index,
  });

  final Club club;
  final int index;

  @override
  State<_ClubCard> createState() => _ClubCardState();
}

class _ClubCardState extends State<_ClubCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Gradient colors for different clubs
  List<Color> _getGradientColors() {
    final gradients = [
      [Colors.purple.shade400, Colors.deepPurple.shade600],
      [Colors.blue.shade400, Colors.cyan.shade600],
      [Colors.pink.shade400, Colors.orange.shade600],
      [Colors.green.shade400, Colors.teal.shade600],
      [Colors.indigo.shade400, Colors.blue.shade600],
      [Colors.red.shade400, Colors.pink.shade600],
    ];
    return gradients[widget.index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: () => context.go('/clubs/${widget.club.id}'),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[1].withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Club Logo/Icon
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: widget.club.clubLogo.isNotEmpty
                              ? NetworkImage(widget.club.clubLogo)
                              : null,
                          child: widget.club.clubLogo.isEmpty
                              ? Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        gradientColors[0].withOpacity(0.3),
                                        gradientColors[1].withOpacity(0.3),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.groups_rounded,
                                    size: 40,
                                    color: gradientColors[1],
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Club Name
                      Expanded(
                        child: Center(
                          child: Text(
                            widget.club.clubName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Explore button/indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
