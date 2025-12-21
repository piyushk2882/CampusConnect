import 'dart:async';

import 'package:animations/animations.dart';
import 'package:campusconnect/app/app.dart';
import 'package:campusconnect/auth/view/auth_page.dart';
import 'package:campusconnect/clubs/clubs.dart';
import 'package:campusconnect/clubs/view/create_event_page.dart';
import 'package:campusconnect/clubs/view/event_details_page.dart';
import 'package:campusconnect/clubs/view/event_details_view_page.dart';
import 'package:campusconnect/clubs/view/event_hub_page.dart';
import 'package:campusconnect/clubs/view/hiring_form_page.dart';
import 'package:campusconnect/clubs/view/manage_events_page.dart';
import 'package:campusconnect/clubs/view/manage_hiring_page.dart';
import 'package:campusconnect/faculties/view/faculty_directory_page.dart';
import 'package:campusconnect/feed/post/view/post_detail_page.dart';
import 'package:campusconnect/feed/post/widgets/post_edit.dart';
import 'package:campusconnect/feed/view/feed_page.dart';
import 'package:campusconnect/home/view/home_page.dart';
import 'package:campusconnect/reels/reels.dart';
import 'package:campusconnect/search/view/search_page.dart';
import 'package:campusconnect/timeline/view/timeline_page.dart';
import 'package:campusconnect/user_profile/user_profile.dart';
import 'package:campusconnect/user_profile/view/verification_required_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:insta_blocks/insta_blocks.dart' hide FeedPage, ReelsPage;
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter router(AppBloc appBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/feed',
    debugLogDiagnostics: true,
    routes: [
      // ===== AUTH PAGE =====
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/users/:user_id',
        name: 'user_profile',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final userId = state.pathParameters['user_id']!;
          return CustomTransitionPage(
            child: UserProfilePage(
              userId: userId,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/posts/:post_id/edit',
        name: 'post_edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final post = state.extra! as PostBlock;

          return NoTransitionPage(child: PostEditPage(post: post));
        },
      ),
      GoRoute(
        path: '/events/:event_id',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['event_id']!;
          return CustomTransitionPage(
            child: EventDetailsViewPage(eventId: eventId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/events/:event_id/edit',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['event_id']!;
          return CustomTransitionPage(
            child: EventDetailsPage(eventId: eventId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/event_hub',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const EventHubPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/faculty_directory',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const FacultyDirectoryPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/posts/:post_id',
        name: 'post_detail',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extraData = state.extra! as Map<String, dynamic>;
          final blocks = extraData['blocks'] as List<PostBlock>;
          final initialIndex = extraData['initialIndex'] as int;

          return CustomTransitionPage(
            child: PostDetailPage(
              blocks: blocks,
              initialIndex: initialIndex,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  );
                },
          );
        },
      ),

      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return HomePage(navigationShell: navigationShell);
        },
        branches: [
          // Feed Branch — default tab (index 0)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                pageBuilder: (context, state) {
                  return CustomTransitionPage(
                    child: FeedPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.horizontal,
                            child: child,
                          );
                        },
                  );
                },
              ),
            ],
          ),
          // Timeline Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timeline',
                pageBuilder: (context, state) {
                  return CustomTransitionPage(
                    child: const TimelinePage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: CurveTween(
                              curve: Curves.easeOut,
                            ).animate(animation),
                            child: child,
                          );
                        },
                  );
                },
                routes: [
                  GoRoute(
                    name: 'search',
                    path: 'search',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final withResult = state.extra as bool?;
                      return NoTransitionPage(
                        key: state.pageKey,
                        child: SearchPage(
                          withResult: withResult,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Explore Clubs Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clubs',
                pageBuilder: (context, state) {
                  return CustomTransitionPage(
                    child: const ClubsPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: CurveTween(
                              curve: Curves.easeOut,
                            ).animate(animation),
                            child: child,
                          );
                        },
                  );
                },
                routes: [
                  GoRoute(
                    path: ':club_id',
                    pageBuilder: (context, state) {
                      final clubId = state.pathParameters['club_id']!;
                      return CustomTransitionPage(
                        child: ClubDetailsPage(clubId: clubId),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SharedAxisTransition(
                                animation: animation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType:
                                    SharedAxisTransitionType.horizontal,
                                child: child,
                              );
                            },
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'manage_events',
                        pageBuilder: (context, state) {
                          final clubId = state.pathParameters['club_id']!;
                          return CustomTransitionPage(
                            child: ManageEventsPage(clubId: clubId),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.horizontal,
                                    child: child,
                                  );
                                },
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'create_event',
                            pageBuilder: (context, state) {
                              final clubId = state.pathParameters['club_id']!;
                              return CustomTransitionPage(
                                child: CreateEventPage(clubId: clubId),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return SharedAxisTransition(
                                        animation: animation,
                                        secondaryAnimation: secondaryAnimation,
                                        transitionType:
                                            SharedAxisTransitionType.horizontal,
                                        child: child,
                                      );
                                    },
                              );
                            },
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'manage_hiring',
                        pageBuilder: (context, state) {
                          final clubId = state.pathParameters['club_id']!;
                          return CustomTransitionPage(
                            child: ManageHiringPage(clubId: clubId),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.horizontal,
                                    child: child,
                                  );
                                },
                          );
                        },
                      ),
                      GoRoute(
                        path: 'apply',
                        pageBuilder: (context, state) {
                          final clubId = state.pathParameters['club_id']!;
                          return CustomTransitionPage(
                            child: HiringFormPage(clubId: clubId),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.horizontal,
                                    child: child,
                                  );
                                },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Reels Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reels',
                pageBuilder: (context, state) {
                  return CustomTransitionPage(
                    child: const ReelsPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: CurveTween(
                              curve: Curves.easeOut,
                            ).animate(animation),
                            child: child,
                          );
                        },
                  );
                },
              ),
            ],
          ),
          // User Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/user',
                pageBuilder: (context, state) {
                  final user = context.select(
                    (AppBloc bloc) => bloc.state.user,
                  );
                  return CustomTransitionPage(
                    child: UserProfilePage(
                      userId: user.id,
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.horizontal,
                            child: child,
                          );
                        },
                  );
                },

                routes: [
                  GoRoute(
                    path: 'create_post',
                    name: 'create_post',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final pickVideo = state.extra as bool? ?? false;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: UserProfileCreatePost(pickVideo: pickVideo),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SharedAxisTransition(
                                animation: animation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType:
                                    SharedAxisTransitionType.horizontal,
                                child: child,
                              );
                            },
                      );
                    },
                    routes: [
                      GoRoute(
                        name: 'publish_post',
                        path: 'publish_post',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (context, state) {
                          final props = state.extra! as CreatePostProps;
                          return CustomTransitionPage(
                            key: state.pageKey,
                            child: CreatePostPage(props: props),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.horizontal,
                                    child: child,
                                  );
                                },
                          );
                        },
                      ),
                      GoRoute(
                        name: 'verification_required',
                        path: 'verification_required',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (context, state) {
                          return CustomTransitionPage(
                            key: state.pageKey,
                            child: const VerificationRequiredPage(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.horizontal,
                                    child: child,
                                  );
                                },
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'edit',
                    name: 'edit_profile',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: UserProfileEdit(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SharedAxisTransition(
                                animation: animation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType:
                                    SharedAxisTransitionType.horizontal,
                                child: child,
                              );
                            },
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'info/:label',
                        name: 'edit_profile_info',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (context, state) {
                          final label = state.pathParameters['label']!;
                          final title =
                              state.uri.queryParameters['title'] ?? label;
                          final value =
                              state.uri.queryParameters['value'] ?? '';
                          final description =
                              state.uri.queryParameters['description'];
                          final infoType = state.extra as ProfileEditInfoType?;

                          return CustomTransitionPage(
                            key: state.pageKey,
                            child: ProfileInfoEditPage(
                              appBarTitle: title,
                              infoLabel: label,
                              infoValue: value,
                              description: description,
                              infoType: infoType ?? ProfileEditInfoType.bio,
                            ),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.horizontal,
                                    child: child,
                                  );
                                },
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'statistics',
                    name: 'user_statistics',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final userId =
                          state.uri.queryParameters['user_id'] ??
                          state.uri.queryParameters['userId'] ??
                          context.select((AppBloc bloc) => bloc.state.user.id);
                      final tabIndex = state.extra as int? ?? 0;

                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: BlocProvider(
                          create: (context) =>
                              UserProfileBloc(
                                  userId: userId,
                                  postsRepository: context
                                      .read<PostsRepository>(),
                                  userRepository: context
                                      .read<UserRepository>(),
                                )
                                ..add(const UserProfileSubscriptionRequested())
                                ..add(
                                  const UserProfileFollowingsCountSubscriptionRequested(),
                                )
                                ..add(
                                  UserProfileFollowersCountSubscriptionRequested(),
                                ),
                          child: UserProfileStatistics(tabIndex: tabIndex),
                        ),
                        transitionsBuilder:
                            (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return SharedAxisTransition(
                                animation: animation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType:
                                    SharedAxisTransitionType.horizontal,
                                child: child,
                              );
                            },
                      );
                    },
                  ),
                  GoRoute(
                    path: 'posts',
                    name: 'user_posts',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final userId = state.uri.queryParameters['user_id']!;
                      final index = (state.uri.queryParameters['index']!).parse
                          .toInt();
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: BlocProvider(
                          create: (context) => UserProfileBloc(
                            userId: userId,
                            postsRepository: context.read<PostsRepository>(),
                            userRepository: context.read<UserRepository>(),
                          ),
                          child: UserProfilePosts(userId: userId, index: index),
                        ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SharedAxisTransition(
                                animation: animation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType:
                                    SharedAxisTransitionType.horizontal,
                                child: child,
                              );
                            },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authenticated = appBloc.state.status == AppStatus.authenticated;
      final onAuthPage = state.matchedLocation == '/auth';
      final isInFeed = state.matchedLocation == '/feed';
      final isCreatePost = state.matchedLocation == '/user/create_post';

      if (isInFeed && !authenticated) return '/auth';

      // Not logged in → always go to auth
      if (!authenticated) return '/auth';

      // Logged in but on auth page → go straight to default tab (feed)
      if (authenticated && onAuthPage) return '/feed';

      return null;
    },
    refreshListenable: GoRouterAppBlocRefreshStream(appBloc.stream),
  );
}

class GoRouterAppBlocRefreshStream extends ChangeNotifier {
  /// {@macro go_router_refresh_stream}
  GoRouterAppBlocRefreshStream(Stream<AppState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((appState) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
