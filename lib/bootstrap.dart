import 'dart:async';
import 'dart:developer';
import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/di/di.dart';
import 'package:campusconnect/l10n/slang/translations.g.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fm;
import 'package:firebase_remote_config_repository/firebase_remote_config_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync_repository/powersync_repository.dart';
import 'package:shared/src/config/app_flavor.dart';

typedef AppBuilder = Future<Widget> Function(PowerSyncRepository, FirebaseRemoteConfigRepository);

/// Background message handler for Firebase Messaging.
Future<void> _firebaseMessagingBackgroundHandler(fm.RemoteMessage message) async {
  // Handle background messages here if needed
  // For now, just log the message
  log('Handling a background message: ${message.messageId}');
}

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log(r'onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log(r'onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(
  AppBuilder builder, {
  required FirebaseOptions options,
  required AppFlavor appFlavor,
  required EnvValue env,
}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      setupDi(appFlavor: appFlavor);

      await Firebase.initializeApp(options: options);

      // Initialize Firebase Messaging
      final messaging = fm.FirebaseMessaging.instance;
      await messaging.requestPermission();
      final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        // Update user pushToken if user is logged in
        // This will be handled in AppBloc or UserRepository
      }

      // Handle background messages
      fm.FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: kIsWeb
            ? HydratedStorageDirectory.web
            : HydratedStorageDirectory(
                (await getTemporaryDirectory()).path,
              ),
      );

      final powerSyncRepository = PowerSyncRepository(env: appFlavor.getenv);
      await powerSyncRepository.initialize();

      final firebaseRemoteConfig = FirebaseRemoteConfig.instance;
      final firebaseRemoteConfigRepository = FirebaseRemoteConfigRepository(
        firebaseRemoteConfig: firebaseRemoteConfig,
      );

      SystemUiOverlayTheme.setPortraitOrientation();

      runApp(TranslationProvider(child: await builder(powerSyncRepository, firebaseRemoteConfigRepository)));
    },
    (error, stack) {
      log(error.toString(), stackTrace: stack);
    },
  );
}
