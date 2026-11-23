// Har bir vizual uslubni bir xil o'yin holatida chizib, PNG qilib saqlaydi.
// Ishga tushirish: flutter test tool/themes_test.dart
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:color_land/game/logic/difficulty.dart';
import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/game/render/game_theme.dart';
import 'package:color_land/game/render/canvas_text.dart';
import 'package:color_land/game/render/palette.dart';
import 'package:color_land/i18n/app_language.dart';
import 'package:color_land/i18n/l10n.dart';
import 'package:color_land/storage/settings_store.dart';
import 'package:color_land/ui/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey shotKey = GlobalKey();

Future<void> loadFonts() async {
  final loader = FontLoader('Roboto');
  for (final path in const [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  ]) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader.addFont(
      Future<ByteData>.value(ByteData.view(file.readAsBytesSync().buffer)),
    );
  }
  await loader.load();
  canvasFontFamily = 'Roboto';
  addTearDown(() => canvasFontFamily = null);
}

Future<void> saveFrame(WidgetTester tester, String path) async {
  final boundary =
      shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final theme in GameTheme.all) {
    testWidgets('uslub: ${theme.id}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = await SettingsStore.load();
      await loadFonts();
      Palette.theme = theme;

      tester.view
        ..physicalSize = const Size(720, 1280)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        L10n(
          controller: LanguageController(store, AppLanguage.uz),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
            home: RepaintBoundary(
              key: shotKey,
              child: GameScreen(
                config: const GameConfig(difficulty: Difficulty.easy),
                colorIndex: 0,
                store: store,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final screen = tester.state<GameScreenState>(find.byType(GameScreen));
      final game = screen.gameForTest;

      const frame = Duration(milliseconds: 16);
      // Hamma uslubda bir xil holat: botlar o'ssin, keyin o'yinchi
      // aylana chizib hudud egallasin va iz bilan to'xtasin.
      game.sim.human.speed = 0;
      for (var i = 0; i < 25 * 60; i++) {
        await tester.pump(frame);
      }
      game.sim.human.speed = game.sim.config.playerSpeed;

      const turnFrames = 300;
      for (var i = 0; i < turnFrames && game.sim.human.alive; i++) {
        game.setSteerAngle(-math.pi / 2 + (i / turnFrames) * 2 * math.pi);
        await tester.pump(frame);
      }
      game.setSteerAngle(-math.pi / 2);
      for (var i = 0; i < 95 && game.sim.human.alive; i++) {
        await tester.pump(frame);
      }
      game.setSteerAngle(0.9);
      for (var i = 0; i < 60 && game.sim.human.alive; i++) {
        await tester.pump(frame);
      }

      await saveFrame(tester, 'build/theme_${theme.id}.png');
      expect(File('build/theme_${theme.id}.png').existsSync(), isTrue);
    });
  }
}
