import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'services/bookmarks_store.dart';
import 'services/palette_store.dart';
import 'services/progress_store.dart';
import 'services/ui_settings_store.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PaletteStore.loadInto(paletteNotifier);
  await BookmarksStore.load();
  await ProgressStore.load();
  await UiSettingsStore.init();
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => ValueListenableBuilder<AppPalette>(
        valueListenable: paletteNotifier,
        builder: (context, palette, _) => ValueListenableBuilder<String>(
          valueListenable: fontFamilyNotifier,
          builder: (context, _, _) => MaterialApp(
          title: 'السراج في بيان غريب القرآن',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildLightTheme(palette),
          darkTheme: buildDarkTheme(palette),
          themeMode: mode,
          home: const HomeScreen(),
        ),
      ),
    ),
  );
  }
}
