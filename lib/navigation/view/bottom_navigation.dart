import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/feed/post/video/video.dart';
import 'package:campusconnect/feed/widgets/feed_page_controller.dart';
import 'package:campusconnect/home/provider/home_provider.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final videoPlayerState = VideoPlayerInheritedWidget.of(
      context,
    ).videoPlayerState;
    final l10n = context.l10n;
    final navigationBarItems = mainNavigationBarItems(
      homeLabel: l10n.homeNavBarItemLabel,
      searchLabel: l10n.searchNavBarItemLabel,
      exploreLabel: l10n.exploreNavBarItemLabel,
      reelsLabel: l10n.reelsNavBarItemLabel,
      userProfileLabel: l10n.profileNavBarItemLabel,
      userProfileAvatar: Icon(Icons.person),
    );
    return BottomNavigationBar(
      currentIndex: navigationShell.currentIndex,
      onTap: (index) {
        HomeProvider().togglePageView(enable: index == 0);
        if ([0, 1, 2, 3].contains(index)) {
          if (index case 0) videoPlayerState.playFeed();
          if (index case 1) videoPlayerState.playTimeline();
          if (index case 2) videoPlayerState.stopAll();
          if (index case 3) videoPlayerState.playReels();
        } else {
          videoPlayerState.stopAll();
        }
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
        if (index == 0) {
          if (!(index == navigationShell.currentIndex)) return;
          FeedPageController().ScrollToTop();
        }
      },
      iconSize: 28,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: navigationBarItems
          .map(
            (e) => BottomNavigationBarItem(
              icon: e.child ?? Icon(e.icon),
              tooltip: e.tooltip,
              label: e.label,
            ),
          )
          .toList(),
    );
  }
}
