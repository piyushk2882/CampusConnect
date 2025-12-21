import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fm;
import 'package:user_repository/user_repository.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required User user,
    required UserRepository userRepository,
  }) : _userRepository = userRepository,
       super(
         user.isAnonymous
             ? const AppState.unauthenticated()
             : AppState.authenticated(user),
       ) {
    on<AppLogoutRequested>(_onAppLogoutRequested);
    on<AppUserChanged>(_onUserChanged);

    _userSubscription = userRepository.user.listen(
      _userChanged,
      onError: addError,
    );

    // Listen to FCM token changes and update user pushToken
    _pushTokenSubscription = fm.FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) async {
        if (!state.user.isAnonymous) {
          await userRepository.updatePushToken(token);
        }
      },
    );
  }

  final UserRepository _userRepository;

  StreamSubscription<User>? _userSubscription;
  StreamSubscription<String>? _pushTokenSubscription;

  void _userChanged(User user) => add(AppUserChanged(user));

  Future<void> _initializeFCMToken() async {
    if (state.user.isAnonymous) return;

    // Request notification permissions
    final settings = await fm.FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus != fm.AuthorizationStatus.authorized) {
      log('Notification permissions not granted');
      return;
    }

    final token = await fm.FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _userRepository.updatePushToken(token);
    }
  }

  Future<void> _onUserChanged(AppUserChanged event, Emitter<AppState> emit) async {
    final user = event.user;

    if (user.isAnonymous) {
      emit(const AppState.unauthenticated());
    } else if (!user.isAnonymous && user.isNewUser) {
      emit(AppState.onboardingRequired(user));
      await _initializeFCMToken();
    } else {
      emit(AppState.authenticated(user));
      await _initializeFCMToken();
    }
  }

  Future<void> _onAppLogoutRequested(
    AppLogoutRequested event,
    Emitter<AppState> emit,
  ) => _userRepository.logOut();

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    _pushTokenSubscription?.cancel();
    return super.close();
  }
}
