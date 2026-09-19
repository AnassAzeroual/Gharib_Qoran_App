// App version shown in the UI.
// Keep in sync with pubspec.yaml `version:` and installer/AlSiraj.iss.

import '../utils/arabic_digits.dart';

const String kAppVersion = '1.0.0';

/// Formats the semantic version (e.g. 1.0.0) using the app-wide numeral
/// system, so it flips between Arabic-Indic (١.٠.٠) and Western (1.0.0).
String appVersionLabel() => kAppVersion
    .split('.')
    .map((part) => displayNumber(int.parse(part)))
    .join('.');