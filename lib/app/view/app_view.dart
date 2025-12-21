import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/app.dart';
import 'package:campusconnect/app/routes/routes.dart';
import 'package:campusconnect/app/view/app_init_utilities.dart';
import 'package:campusconnect/app/view/splash_screen.dart';

import 'package:campusconnect/l10n/l10n.dart';
import 'package:campusconnect/selector/locale/bloc/locale_bloc.dart';
import 'package:campusconnect/selector/theme/bloc/theme_mode_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 8), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _showSplash
          ? const SplashScreen(key: ValueKey('splash'))
          : _MainApp(key: const ValueKey('main')),
    );
  }
}

class _MainApp extends StatelessWidget {
  const _MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routerConfig = router(context.read<AppBloc>());
    context.customAdaptiveColor(light: AppColors.red, dark: AppColors.blue);
    return BlocBuilder<LocaleBloc, Locale>(
      builder: (context, locale) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => LocaleSettings.setLocaleRaw(locale.languageCode),
        );
        return BlocBuilder<ThemeModeBloc, ThemeMode>(
          builder: (context, themeMode) {
            return AnimatedSwitcher(
              duration: 350.ms,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  themeMode: themeMode,
                  theme: const AppTheme().theme,
                  darkTheme: const AppDarkTheme().theme,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) {
                    initUtilities(context, locale);
                    return Stack(
                      children: [
                        child!,
                        AppSnackbar(
                          key: SnackBarKey,
                        ),
                        AppLoadingIndeterminate(key: loadingIndeterminateKey),
                      ],
                    );
                  },
                  routerConfig: routerConfig,
                  locale: locale,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
