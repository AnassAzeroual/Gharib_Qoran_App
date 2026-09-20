// App version shown in the UI.
// Keep in sync with pubspec.yaml `version:` and installer/AlSiraj.iss.

const String kAppVersion = '1.1.0';

/// The app version, always shown with Western digits regardless of the
/// numeral system toggle.
String appVersionLabel() => kAppVersion;