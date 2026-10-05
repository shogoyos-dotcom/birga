// O'yinning haqiqiy kadrlarini PNG qilib saqlaydi — qo'lda ko'rib tekshirish
// uchun. Ishga tushirish: flutter test tool/screenshot_test.dart
//
// `tool/` papkasi analyzer uchun test papkasi emas, shuning uchun
// test-only a'zolar haqidagi ogohlantirishlarni o'chiramiz.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:color_land/game/logic/difficulty.dart';
import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/i18n/app_language.dart';
import 'package:color_land/i18n/l10n.dart';
import 'package:color_land/storage/settings_store.dart';
import 'package:color_land/ui/game_screen.dart';
import 'package:color_land/ui/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey shotKey = GlobalKey();

Future<void> saveFrame(WidgetTester tester, String path) async {
  final boundary =
      shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  // Engine chaqiruvlari haqiqiy async talab qiladi.
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// Widget testlarida haqiqiy shrift bo'lmaydi — matn kvadrat bo'lib
/// chiqadi. Skrinshot o'qilishi uchun tizim shriftini yuklaymiz.
Future<void> loadFonts() async {
  const files = <String, List<String>>{
    'Roboto': [
      '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
      '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    ],
  };
  for (final entry in files.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final file = File(path);
      if (!file.existsSync()) continue;
      loader.addFont(
        Future<ByteData>.value(ByteData.view(file.readAsBytesSync().buffer)),
      );
    }
    await loader.load();
  }
}

Widget wrap(SettingsStore store, AppLanguage lang, Widget child) {
  return L10n(
    controller: LanguageController(store, lang),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: RepaintBoundary(key: shotKey, child: child),
    ),
  );
}

void main() {
  late SettingsStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'best_percent': 18.42,
      'best_kills': 7,
    });
    store = await SettingsStore.load();
    await loadFonts();
  });

  void sizeView(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(720, 1280)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('menyu', (tester) async {
    sizeView(tester);
    await tester.pumpWidget(
      wrap(store, AppLanguage.uz, MenuScreen(store: store)),
    );
    await tester.pumpAndSettle();
    await saveFrame(tester, 'build/shot_menu.png');
  });

  testWidgets('menyu — English', (tester) async {
    sizeView(tester);
    await tester.pumpWidget(
      wrap(store, AppLanguage.en, MenuScreen(store: store)),
    );
    await tester.pumpAndSettle();
    await saveFrame(tester, 'build/shot_menu_en.png');
  });

  testWidgets("o'yin — botlar bilan", (tester) async {
    sizeView(tester);
    await tester.pumpWidget(
      wrap(
        store,
        AppLanguage.uz,
        GameScreen(
          config: const GameConfig(botCount: 9, difficulty: Difficulty.easy),
          colorIndex: 0,
          store: store,
        ),
      ),
    );
    await tester.pump();
    final screen = tester.state<GameScreenState>(find.byType(GameScreen));
    final game = screen.gameForTest;

    const frame = Duration(milliseconds: 16);
    Future<void> run(double angle, int frames) async {
      game.setSteerAngle(angle);
      for (var i = 0; i < frames; i++) {
        if (!game.sim.human.alive) return;
        await tester.pump(frame);
      }
    }

    // Botlar hududlarini kengaytirishi uchun 25 soniya beramiz.
    game.sim.human.speed = 0;
    for (var i = 0; i < 25 * 60; i++) {
      await tester.pump(frame);
    }
    game.sim.human.speed = game.sim.config.playerSpeed;

    // O'yinchi erkin burchakda, egri yo'l bo'ylab yuradi — harakat
    // to'rt tomonga cheklanmaganini ko'rsatish uchun.
    const turnFrames = 300;
    for (var i = 0; i < turnFrames && game.sim.human.alive; i++) {
      final t = i / turnFrames;
      game.setSteerAngle(-math.pi / 2 + t * 2 * math.pi);
      await tester.pump(frame);
    }
    await run(math.pi / 2, 20);

    // ignore: avoid_print
    print(
      "o'yinchi: ${game.sim.grid.percentOf(1).toStringAsFixed(2)}%  "
      'tirik: ${game.sim.players.where((p) => p.alive).length}/'
      '${game.sim.players.length}  '
      "o'ldirishlar: ${game.sim.human.kills}",
    );
    await saveFrame(tester, 'build/shot_game.png');

    // Natija oynasi: o'lim o'yin tsikli ichida bo'lishi kerak, aks holda
    // ekran o'lim haqida xabar olmaydi — shuning uchun devorga qarab
    // yuramiz.
    game.setSteerAngle(-math.pi / 2);
    for (var i = 0; i < 1500 && game.sim.human.alive; i++) {
      await tester.pump(frame);
    }
    // Flame o'yini doim tiklanadi, shuning uchun pumpAndSettle ishlamaydi.
    // Natija oynasi rekordni saqlashni kutadi — bir necha kadr kerak.
    for (var i = 0; i < 40; i++) {
      await tester.pump(frame);
    }
    await saveFrame(tester, 'build/shot_result.png');
  });
}
