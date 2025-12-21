import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/home/provider/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedAppBar extends StatelessWidget {
  const FeedAppBar({required this.innerBoxIsScrolled, super.key});

  final bool innerBoxIsScrolled;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      sliver: SliverAppBar(
        centerTitle: false,
        forceElevated: innerBoxIsScrolled,
        title: const FeedLogo(fit: BoxFit.contain),
        floating: true,
        snap: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'event_hub') {
                context.push('/event_hub');
              } else if (value == 'clubs') {
                HomeProvider().animateToPage(2);
              } else if (value == 'faculty_directory') {
                context.push('/faculty_directory');
              } else if (value == 'college_maps') {
                launchUrl(
                  Uri.parse(
                    'https://indoor-navigation-system.vercel.app/',
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'event_hub',
                child: Text('Event Hub'),
              ),
              const PopupMenuItem<String>(
                value: 'clubs',
                child: Text('Project Hub'),
              ),
              const PopupMenuItem<String>(
                value: 'faculty_directory',
                child: Text('Faculty Directory'),
              ),
              const PopupMenuItem<String>(
                value: 'college_maps',
                child: Text('College Maps'),
              ),
            ],
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
    );
  }
}
