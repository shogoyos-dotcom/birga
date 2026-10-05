import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/game/logic/game_events.dart';
import 'package:color_land/game/logic/match.dart';
import 'package:color_land/game/render/color_land_game.dart';
import 'package:color_land/game/render/shape_painter.dart';
import 'package:color_land/game/render/palette.dart';
import 'package:color_land/i18n/app_language.dart';
import 'package:color_land/i18n/l10n.dart';
import 'package:color_land/storage/settings_store.dart';
import 'package:color_land/ui/game_screen.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ColorLandGame makeGame({int size = 64, int bots = 0, int seed = 1}) {
  return ColorLandGame(
    sim: createMatch(
      config: GameConfig(gridWidth: size, gridHeight: size, botCount: bots),
      playerColorIndex: 0,
      playerName: 'Siz',
      availableColors: Palette.colorCount,
      random: math.Random(seed),
    ),
  );
}

void main() {
  group('Hudud shakli keshi', () {
    test("hudud o'zgarmaguncha shakl qayta chizilmaydi", () {
      final game = makeGame();
      final shapes = TerritoryShapes(game.sim.grid, kCellSize);
      final visible = Rect.fromLTWH(0, 0, 64 * kCellSize, 64 * kCellSize);

      void draw() {
        final rec = ui.PictureRecorder();
        shapes.render(ui.Canvas(rec, visible), game.sim.players, visible);
        rec.endRecording().dispose();
      }

      draw();
      expect(shapes.cachedCount, 1, reason: 'bitta o\'yinchi');
      expect(shapes.lastRebuildCount, 1);

      draw();
      expect(shapes.lastRebuildCount, 0, reason: "o'zgarish yo'q");

      // Hudud o'zgarsa — shakl qayta yoziladi.
      game.sim.grid.setOwner(3, 3, 1);
      draw();
      expect(shapes.lastRebuildCount, 1);

      // Begona o'yinchining hududi o'zgarsa, bizniki tegilmaydi.
      game.sim.grid.setOwner(40, 40, 2);
      draw();
      expect(shapes.lastRebuildCount, 0);

      shapes.dispose();
      expect(shapes.cachedCount, 0);
    });

    test("ko'rinmaydigan hudud chizilmaydi", () {
      final game = makeGame();
      final shapes = TerritoryShapes(game.sim.grid, kCellSize);
      // O'yinchidan juda uzoqdagi soha.
      final far = Rect.fromLTWH(10000, 10000, 100, 100);
      final rec = ui.PictureRecorder();
      shapes.render(ui.Canvas(rec, far), game.sim.players, far);
      rec.endRecording().dispose();
      expect(
        shapes.cachedCount,
        0,
        reason: 'ekrandan tashqaridagi o\'tkazib yuboriladi',
      );
      shapes.dispose();
    });

    test("bo'sh panjara chizishda xato bermaydi", () {
      final game = makeGame(size: 32);
      final shapes = TerritoryShapes(game.sim.grid, kCellSize);
      final visible = Rect.fromLTWH(-500, -500, 2000, 2000);
      final rec = ui.PictureRecorder();
      expect(
        () => shapes.render(ui.Canvas(rec, visible), game.sim.players, visible),
        returnsNormally,
      );
      rec.endRecording().dispose();
      shapes.dispose();
    });
  });

  group('Palette', () {
    test('har rang uchun uch variant bor va bir-biridan farq qiladi', () {
      for (var i = 0; i < Palette.colorCount; i++) {
        expect(Palette.head(i), isNot(Palette.territory(i)));
        expect(Palette.head(i), isNot(Palette.trail(i)));
      }
      expect(Palette.territoryValues.length, Palette.colorCount);
      expect(Palette.trailValues.length, Palette.colorCount);
    });
  });

  testWidgets("o'yin ekrani ishga tushadi va o'yinchi harakatlanadi", (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = await SettingsStore.load();

    await tester.pumpWidget(
      L10n(
        controller: LanguageController(store, AppLanguage.uz),
        child: MaterialApp(
          home: GameScreen(
            config: const GameConfig(
              gridWidth: 64,
              gridHeight: 64,
              botCount: 4,
            ),
            colorIndex: 0,
            store: store,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    final game = tester
        .widget<GameWidget<ColorLandGame>>(
          find.byType(GameWidget<ColorLandGame>),
        )
        .game!;
    final human = game.sim.human;
    expect(human.alive, isTrue);
    expect(game.sim.players.length, 5, reason: "o'yinchi + 4 bot");
    final startX = human.x;
    final startY = human.y;

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final moved = math.sqrt(
      math.pow(human.x - startX, 2) + math.pow(human.y - startY, 2),
    );
    expect(moved, greaterThan(0.5), reason: 'doimiy tezlikda harakatlanadi');
    expect(tester.takeException(), isNull);
  });

  testWidgets("natija oynasi o'limdan oldingi foizni ko'rsatadi", (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = await SettingsStore.load();

    await tester.pumpWidget(
      L10n(
        controller: LanguageController(store, AppLanguage.uz),
        child: MaterialApp(
          home: GameScreen(
            config: const GameConfig(
              gridWidth: 64,
              gridHeight: 64,
              botCount: 0,
            ),
            colorIndex: 0,
            store: store,
          ),
        ),
      ),
    );
    await tester.pump();
    final game = tester
        .widget<GameWidget<ColorLandGame>>(
          find.byType(GameWidget<ColorLandGame>),
        )
        .game!;

    // Devorga qarab yuramiz — o'lim o'yin tsikli ichida sodir bo'lsin.
    game.setSteerAngle(-math.pi / 2);
    var livePercent = 0.0;
    for (var i = 0; i < 1200 && game.sim.human.alive; i++) {
      livePercent = game.sim.grid.percentOf(game.sim.human.id);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.sim.human.alive, isFalse);
    expect(game.sim.human.deathCause, DeathCause.wall);
    expect(livePercent, greaterThan(0));

    // O'lim hududni tozalaydi — natija esa oldingi holatni ko'rsatishi kerak.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(game.sim.grid.percentOf(game.sim.human.id), 0);
    expect(
      game.hud.value.percent,
      closeTo(livePercent, 0.01),
      reason: "0% emas, o'limdan oldingi foiz ko'rinishi kerak",
    );
    expect(game.hud.value.rank, lessThanOrEqualTo(game.hud.value.alivePlayers));
    expect(find.text("O'yin tugadi"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
