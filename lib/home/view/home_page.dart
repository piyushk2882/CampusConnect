import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/feed/post/video/video.dart';
import 'package:campusconnect/home/provider/home_provider.dart';
import 'package:campusconnect/home/view/project_hub_page.dart';
import 'package:campusconnect/navigation/view/bottom_navigation.dart';
import 'package:campusconnect/user_profile/widgets/user_profile_create_post.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return HomeView(
      navigationShell: navigationShell,
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late VideoPlayerState _videoPlayerState;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 1)
      ..addListener(_onPageScroll);

    _videoPlayerState = VideoPlayerState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeProvider().setPageController(_pageController);
    });
  }

  void _onPageScroll() {
    _pageController.position.isScrollingNotifier.addListener(_isPageScrolling);
  }

  void _isPageScrolling() {
    final isScrolling =
        _pageController.position.isScrollingNotifier.value == true;
    final mainPageView = _pageController.page == 1;
    final navigationBarIndex = widget.navigationShell.currentIndex;
    final isFeed = !isScrolling && mainPageView && navigationBarIndex == 0;
    final isTimeline = !isScrolling && mainPageView && navigationBarIndex == 1;
    final isReels = !isScrolling && mainPageView && navigationBarIndex == 3;

    if (isScrolling) {
      _videoPlayerState.stopAll();
    }
    switch ((isFeed, isTimeline, isReels)) {
      case (true, false, false):
        _videoPlayerState.playFeed();
      case (false, true, false):
        _videoPlayerState.playTimeline();
      case (false, false, true):
        _videoPlayerState.playReels();
      case _:
        _videoPlayerState.stopAll();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.navigationShell.currentIndex == 0 &&
        !HomeProvider().enablePageView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HomeProvider().togglePageView();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.path;
    final isHomeFeed = currentPath == '/feed';
    return VideoPlayerInheritedWidget(
      videoPlayerState: _videoPlayerState,
      child: ListenableBuilder(
        listenable: HomeProvider(),
        builder: (context, child) {
          return PageView.builder(
            itemCount: 3,
            controller: _pageController,
            physics:
                HomeProvider().enablePageView &&
                    widget.navigationShell.currentIndex == 0 &&
                    isHomeFeed
                ? null
                : const NeverScrollableScrollPhysics(),
            onPageChanged: (page) {
              if (page == 1 && widget.navigationShell.currentIndex != 0) {
                HomeProvider().togglePageView(enable: false);
              }
            },
            itemBuilder: (context, index) {
              return switch (index) {
                0 => UserProfileCreatePost(
                  canPop: false,
                  onPopInvoked: () => HomeProvider().animateToPage(1),
                  onBackButtonTap: () => HomeProvider().animateToPage(1),
                ),
                2 => const ProjectHubPage(),
                _ => AppScaffold(
                  body: widget.navigationShell,
                  bottomNavigationBar: BottomNavBar(
                    navigationShell: widget.navigationShell,
                  ),
                ),
              };
            },
          );
        },
      ),
    );
  }
}
