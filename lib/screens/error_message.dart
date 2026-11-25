import 'package:flutter/material.dart';

import '../gen/app_localizations.dart';

/// Resolves common engine failures to localized text. Unknown errors are
/// returned as plain text with the Dart exception prefix removed.
String friendlyError(BuildContext context, Object error) {
  final l = AppLocalizations.of(context)!;
  final text = '$error';
  for (final pattern in _errorPatterns) {
    final match = pattern.$1.firstMatch(text);
    if (match != null) return pattern.$2(l);
  }
  return text
      .replaceFirst('StateError: ', '')
      .replaceFirst('Exception: ', '')
      .replaceFirst('FormatException: ', '');
}

final _errorPatterns = <(RegExp, String Function(AppLocalizations l))>[
  (RegExp(r'HTTP Error 403|403 Forbidden', caseSensitive: false), (l) => l.err403),
  (RegExp(r'Sign in|sign-in|not a bot', caseSensitive: false), (l) => l.errSignin),
  (RegExp(r'video is unavailable|This video is unavailable', caseSensitive: false), (l) => l.errUnavailable),
  (RegExp(r'Private video', caseSensitive: false), (l) => l.errPrivate),
  (RegExp(r'HTTP Error 404|404 Not Found', caseSensitive: false), (l) => l.err404),
  (RegExp(r'ffmpeg.*not found|ffmpeg.*required', caseSensitive: false), (l) => l.errFfmpeg),
  (RegExp(r'aria2c.*not installed', caseSensitive: false), (l) => l.errAria2),
  (RegExp(r'Live event is in progress', caseSensitive: false), (l) => l.errLive),
];
