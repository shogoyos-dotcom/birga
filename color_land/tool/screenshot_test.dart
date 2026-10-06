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
import 'package:color_land/game/render/avatar_painter.dart';
import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/i18n/app_language.dart';
import 'package:color_land/i18n/l10n.dart';
import 'package:color_land/services/audio_service.dart';
import 'package:color_land/storage/settings_store.dart';
import 'package:color_land/ui/game_screen.dart';
import 'package:color_land/ui/menu_screen.dart';
import 'package:color_land/ui/theme/arcade.dart';
import 'package:color_land/ui/profile_screen.dart';
import 'package:color_land/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/widget_helpers.dart';

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
    // Emoji va bayroqlar uchun alohida familiya: qurilmada buni tizim
    // beradi, test muhitida esa o'zimiz yuklaymiz.
    'NotoColorEmoji': ['/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf'],
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
  avatarFontFallback = const <String>['NotoColorEmoji'];
  addTearDown(() => avatarFontFallback = null);
}

Widget wrap(SettingsStore store, AppLanguage lang, Widget child) {
  return L10n(
    controller: LanguageController(store, lang),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Arcade.themeData().copyWith(
        textTheme: Arcade.themeData().textTheme.apply(fontFamily: 'Roboto'),
      ),
      home: RepaintBoundary(key: shotKey, child: child),
    ),
  );
}

void main() {
  late SettingsStore store;

  setUp(() async {
    // Test muhitida haqiqiy audio qurilmasi yo'q.
    AudioService.disabled = true;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'best_percent': 18.42,
      'best_kills': 7,
      'nickname': 'Alisher',
      'avatar': 'flag:UZ',
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

  testWidgets('menyu — keng ekran', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      wrap(store, AppLanguage.uz, MenuScreen(store: store)),
    );
    await tester.pumpAndSettle();
    await saveFrame(tester, 'build/shot_menu_wide.png');
  });

  testWidgets('sozlamalar', (tester) async {
    sizeView(tester);
    await tester.pumpWidget(
      wrap(
        store,
        AppLanguage.uz,
        SettingsScreen(
          store: store,
          audio: AudioService(
            musicEnabled: true,
            soundEnabled: true,
            vibrationEnabled: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await saveFrame(tester, 'build/shot_settings.png');

    // Pastki qism — ovoz sozlamalari.
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();
    await saveFrame(tester, 'build/shot_settings_audio.png');
  });

  testWidgets('profil', (tester) async {
    sizeView(tester);
    await tester.pumpWidget(
      wrap(store, AppLanguage.uz, ProfileScreen(store: store, colorIndex: 0)),
    );
    await tester.pumpAndSettle();
    await saveFrame(tester, 'build/shot_profile.png');

    // Bayroqlar varag'i.
    await tester.tap(find.text('Bayroq'));
    await tester.pumpAndSettle();
    await saveFrame(tester, 'build/shot_profile_flags.png');

    // Odam tasvirlari varag'i.
    await tester.tap(find.text('Odam'));
    await tester.pumpAndSettle();
    await saveFrame(tester, 'build/shot_profile_figures.png');

    // Emoji varag'i.
    await tester.tap(find.text('Emoji'));
    await tester.pumpAndSettle();
    await saveFrame(tester, 'build/shot_profile_emoji.png');
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
          // Skrinshot har safar bir xil chiqsin.
          random: math.Random(11),
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
    // Hududdan uzoqroq chiqib to'xtaymiz — iz ham ko'rinsin.
    await run(-math.pi / 2, 95);
    await run(0.9, 60);

    // ignore: avoid_print
    print(
      "o'yinchi: ${game.sim.grid.percentOf(1).toStringAsFixed(2)}%  "
      'tirik: ${game.sim.players.where((p) => p.alive).length}/'
      '${game.sim.players.length}  '
      "o'ldirishlar: ${game.sim.human.kills}",
    );
    await saveFrame(tester, 'build/shot_game.png');

    // Pauza oynasi.
    await tester.tap(find.byTooltip('Pauza'));
    await tester.pump(frame);
    await tester.pump(frame);
    await saveFrame(tester, 'build/shot_pause.png');
    await tester.tap(find.text('DAVOM ETISH'));
    await tester.pump(frame);

    // Natija oynasi: o'lim o'yin tsikli ichida bo'lishi kerak, aks holda
    // ekran o'lim haqida xabar olmaydi. Chegara endi o'ldirmaydi,
    // shuning uchun o'yinchi o'z izini kesadi.
    await dieBySelfCross(tester, game);
    for (var i = 0; i < 40; i++) {
      await tester.pump(frame);
    }
    await saveFrame(tester, 'build/shot_result.png');
  });
}
