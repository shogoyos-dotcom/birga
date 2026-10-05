import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:color_land/game/logic/difficulty.dart';
import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/game/logic/game_world.dart';
import 'package:color_land/game/logic/match.dart';
import 'package:color_land/game/logic/territory_capture.dart';
import 'package:color_land/game/render/color_land_game.dart';
import 'package:color_land/game/render/grid_renderer.dart';
import 'package:color_land/game/render/palette.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Panjarani botlar bilan to'ldirib, "o'yin o'rtasi" holatini yasaydi.
GameWorld filledWorld({double seconds = 120, int seed = 4}) {
  final world = createMatch(
    config: const GameConfig(difficulty: Difficulty.hard),
    playerColorIndex: 0,
    playerName: 'Siz',
    availableColors: Palette.colorCount,
    random: math.Random(seed),
  );
  const dt = 1 / 60;
  for (var i = 0; i < (seconds / dt).round(); i++) {
    world.update(dt);
  }
  return world;
}

void main() {
  test('o\'yin o\'rtasida panjara haqiqatan to\'ladi', () {
    final world = filledWorld();
    final filled = world.config.cellCount - world.grid.territoryOf(0);
    final percent = filled * 100 / world.config.cellCount;
    // ignore: avoid_print
    print('to\'ldirilgan maydon: ${percent.toStringAsFixed(1)}%');
    expect(percent, greaterThan(12), reason: 'test haqiqiy yukni o\'lchasin');
  });

  test('mantiq yangilanishi kadr byudjetiga sig\'adi', () {
    final world = filledWorld();
    const dt = 1 / 60;
    // Isitish.
    for (var i = 0; i < 120; i++) {
      world.update(dt);
    }

    final sw = Stopwatch()..start();
    const frames = 1800; // 30 soniya
    for (var i = 0; i < frames; i++) {
      world.update(dt);
    }
    sw.stop();
    final perFrameUs = sw.elapsedMicroseconds / frames;
    // ignore: avoid_print
    print('mantiq: ${perFrameUs.toStringAsFixed(1)} µs/kadr (10 o\'yinchi)');
    expect(
      perFrameUs,
      lessThan(2000),
      reason: 'kadr byudjeti 16 600 µs; mantiq uning kichik qismi bo\'lsin',
    );
  });

  test('keshlangan panjara chizish kadr byudjetiga sig\'adi', () {
    final world = filledWorld();
    final renderer = GridRenderer(world.grid, kCellSize, world.colorIndexById);

    // Ekranda ko'rinadigan maydon kameraga mos (portret 16:9).
    final human = world.human;
    final visible = Rect.fromCenter(
      center: Offset(human.x * kCellSize, human.y * kCellSize),
      width: kVisibleCells * kCellSize,
      height: kVisibleCells * (16 / 9) * kCellSize,
    );

    double drawOnce() {
      final sw = Stopwatch()..start();
      final rec = ui.PictureRecorder();
      renderer.render(ui.Canvas(rec, visible), visible);
      rec.endRecording().dispose();
      sw.stop();
      return sw.elapsedMicroseconds.toDouble();
    }

    renderer.invalidateDirty();
    final firstUs = drawOnce();
    final rebuilt = renderer.lastRebuildCount;

    // Keyingi kadrlar — hammasi keshdan.
    const frames = 600;
    final sw = Stopwatch()..start();
    for (var i = 0; i < frames; i++) {
      final rec = ui.PictureRecorder();
      renderer.render(ui.Canvas(rec, visible), visible);
      rec.endRecording().dispose();
    }
    sw.stop();
    final cachedUs = sw.elapsedMicroseconds / frames;

    // ignore: avoid_print
    print(
      'chizish: birinchi kadr ${firstUs.toStringAsFixed(0)} µs '
      '($rebuilt chunk yozildi), keshdan ${cachedUs.toStringAsFixed(1)} µs/kadr',
    );

    expect(rebuilt, lessThanOrEqualTo(40), reason: 'faqat ko\'rinadiganlari');
    expect(
      renderer.lastRebuildCount,
      0,
      reason: 'keyin hech biri qayta yozilmaydi',
    );
    expect(cachedUs, lessThan(1500));
    renderer.dispose();
  });

  test('harakat paytida bir kadrda kam chunk qayta yoziladi', () {
    final world = filledWorld();
    final renderer = GridRenderer(world.grid, kCellSize, world.colorIndexById);
    renderer.invalidateDirty();

    // Keshni oldindan to'ldiramiz — birinchi kadr har doim qimmat bo'ladi,
    // bizni esa harakat paytidagi barqaror holat qiziqtiradi.
    {
      final human = world.human;
      final visible = Rect.fromCenter(
        center: Offset(human.x * kCellSize, human.y * kCellSize),
        width: kVisibleCells * kCellSize,
        height: kVisibleCells * (16 / 9) * kCellSize,
      );
      for (var i = 0; i < 3; i++) {
        final rec = ui.PictureRecorder();
        renderer.render(ui.Canvas(rec, visible), visible);
        rec.endRecording().dispose();
      }
    }

    const dt = 1 / 60;
    var totalRebuilds = 0;
    var worstFrame = 0;
    const frames = 900; // 15 soniya

    for (var i = 0; i < frames; i++) {
      world.update(dt);
      renderer.invalidateDirty();
      final human = world.human;
      final visible = Rect.fromCenter(
        center: Offset(human.x * kCellSize, human.y * kCellSize),
        width: kVisibleCells * kCellSize,
        height: kVisibleCells * (16 / 9) * kCellSize,
      );
      final rec = ui.PictureRecorder();
      renderer.render(ui.Canvas(rec, visible), visible);
      rec.endRecording().dispose();
      totalRebuilds += renderer.lastRebuildCount;
      if (renderer.lastRebuildCount > worstFrame) {
        worstFrame = renderer.lastRebuildCount;
      }
    }

    // ignore: avoid_print
    print(
      'chunk qayta yozish: o\'rtacha '
      '${(totalRebuilds / frames).toStringAsFixed(2)}/kadr, eng ko\'pi $worstFrame',
    );
    expect(totalRebuilds / frames, lessThan(4));
    expect(
      worstFrame,
      lessThanOrEqualTo(GridRenderer.kRebuildBudget + 6),
      reason:
          'kamera yangi chunklar ustiga siljiganda ular birinchi marta '
          "yoziladi; eskirganlari esa byudjet bilan cheklangan",
    );
    renderer.dispose();
  });

  test("hudud egallash bir kadrda tugaydi", () {
    final world = filledWorld();
    final grid = world.grid;
    final capturer = TerritoryCapturer(grid);
    final human = world.human;

    // Xaritani kesib o'tuvchi uzun iz — eng og'ir holat.
    final trail = <int>[];
    for (var x = 2; x < grid.width - 2; x++) {
      final i = grid.index(x, grid.height ~/ 2);
      grid.setTrailIndex(i, human.id);
      trail.add(i);
    }

    // Isitish uchun bir marta, keyin o'lchaymiz.
    capturer.capture(human.id, const []);
    final sw = Stopwatch()..start();
    final res = capturer.capture(human.id, trail);
    sw.stop();
    // ignore: avoid_print
    print(
      "eng og'ir egallash: ${sw.elapsedMicroseconds} µs "
      '(${res.count} katak)',
    );
    expect(sw.elapsedMilliseconds, lessThan(16));
  });

  test("eng yomon kadr ham byudjetga sig'adi", () {
    final world = filledWorld();
    const dt = 1 / 60;
    var worstUs = 0;
    for (var i = 0; i < 3600; i++) {
      final sw = Stopwatch()..start();
      world.update(dt);
      sw.stop();
      if (sw.elapsedMicroseconds > worstUs) worstUs = sw.elapsedMicroseconds;
    }
    // ignore: avoid_print
    print("eng og'ir mantiq kadri: $worstUs µs (60 soniyalik o'yin)");
    expect(worstUs, lessThan(16000));
  });
}
