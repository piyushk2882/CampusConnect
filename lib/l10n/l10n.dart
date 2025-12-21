import 'package:campusconnect/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:campusconnect/l10n/gen/app_localizations.dart';
export 'slang/translations.g.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
