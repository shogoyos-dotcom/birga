import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/render/palette.dart';
import 'i18n/app_language.dart';
import 'i18n/l10n.dart';
import 'storage/settings_store.dart';
import 'ui/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final store = await SettingsStore.load();
  // Til tanlanmagan bo'lsa — tizim tiliga moslashtiramiz.
  final language =
      store.language ??
      AppLanguage.fromSystem(
        WidgetsBinding.instance.platformDispatcher.locales,
      );

  runApp(ColorLandApp(store: store, initialLanguage: language));
}

class ColorLandApp extends StatefulWidget {
  const ColorLandApp({
    super.key,
    required this.store,
    required this.initialLanguage,
  });

  final SettingsStore store;
  final AppLanguage initialLanguage;

  @override
  State<ColorLandApp> createState() => _ColorLandAppState();
}

class _ColorLandAppState extends State<ColorLandApp> {
  late final LanguageController _language = LanguageController(
    widget.store,
    widget.initialLanguage,
  );

  @override
  void dispose() {
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return L10n(
      controller: _language,
      child: AnimatedBuilder(
        animation: _language,
        builder: (context, _) => MaterialApp(
          title: 'Color Land',
          debugShowCheckedModeBanner: false,
          locale: _language.language.locale,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Palette.heads.first),
            scaffoldBackgroundColor: Palette.background,
          ),
          home: MenuScreen(store: widget.store),
        ),
      ),
    );
  }
}
