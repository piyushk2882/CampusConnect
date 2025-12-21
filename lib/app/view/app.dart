import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/bloc/app_bloc.dart';
import 'package:campusconnect/app/view/app_view.dart';
import 'package:campusconnect/feed/bloc/feed_bloc.dart';
import 'package:campusconnect/selector/locale/bloc/locale_bloc.dart';
import 'package:campusconnect/selector/theme/bloc/theme_mode_bloc.dart';
import 'package:firebase_remote_config_repository/firebase_remote_config_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:search_repository/search_repository.dart';
import 'package:user_repository/user_repository.dart';

final SnackBarKey = GlobalKey<AppSnackbarState>();

final loadingIndeterminateKey = GlobalKey<AppLoadingIndeterminateState>();

class App extends StatelessWidget {
  const App({
    required this.user,
    required this.userRepository,
    required this.postsRepository,
    required this.searchRepository,
    required this.firebaseRemoteConfigRepository,
    super.key,
  });

  final User user;
  final UserRepository userRepository;
  final PostsRepository postsRepository;
  final SearchRepository searchRepository;
  final FirebaseRemoteConfigRepository firebaseRemoteConfigRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(
          value: userRepository,
        ),
        RepositoryProvider.value(value: postsRepository),
        RepositoryProvider.value(value: searchRepository),
        RepositoryProvider.value(value: firebaseRemoteConfigRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AppBloc(
              user: user,
              userRepository: userRepository,
            ),
          ),
          BlocProvider(
            create: (context) => LocaleBloc(),
          ),
          BlocProvider(create: (_) => ThemeModeBloc()),
          BlocProvider(
            create: (context) => FeedBloc(
              postsRepository: context.read<PostsRepository>(),
              firebaseRemoteConfigRepository: context
                  .read<FirebaseRemoteConfigRepository>(),
            ),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

void toggleLoadingIndeterminate({bool enable = true, bool autoHide = false}) =>
    loadingIndeterminateKey.currentState?.setVisibility(
      visible: enable,
      autoHide: autoHide,
    );

void openSnackBar(
  SnackbarMessage message, {
  bool clearIfQueue = false,
  bool undismissable = false,
}) {
  SnackBarKey.currentState?.post(
    message,
    clearIfQueue: clearIfQueue,
    undismissable: undismissable,
  );
}

void closeSnackBars() => SnackBarKey.currentState?.closeAll();
