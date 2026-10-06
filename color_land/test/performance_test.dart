import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:color_land/game/logic/difficulty.dart';
import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/game/logic/game_world.dart';
import 'package:color_land/game/logic/match.dart';
import 'package:color_land/game/logic/territory_capture.dart';
import 'package:color_land/game/render/avatar_painter.dart';
import 'package:color_land/game/render/color_land_game.dart';
import 'package:color_land/game/render/shape_painter.dart';
import 'package:color_land/ui/widgets/mini_map.dart';
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

/// Kameraning eng to'la joyi: hududi eng katta o'yinchi atrofi.
///
/// Oldin bu o'yinchining o'zi edi, lekin u o'lib qolsa (urug' o'zgarsa)
/// ekran bo'shab, o'lchov ma'nosiz bo'lib qolardi.
Rect busiestView(GameWorld world) {
  var best = world.players.first;
  var bestTerritory = -1;
  for (final p in world.players) {
    final t = world.grid.territoryOf(p.id);
    if (t > bestTerritory) {
      bestTerritory = t;
      best = p;
    }
  }
  final b = world.grid.boundsOf(best.id);
  final center = b == null
      ? Offset(best.x * kCellSize, best.y * kCellSize)
      : Offset((b.$1 + b.$3) / 2 * kCellSize, (b.$2 + b.$4) / 2 * kCellSize);
  return Rect.fromCenter(
    center: center,
    width: kVisibleCells * kCellSize,
    height: kVisibleCells * (16 / 9) * kCellSize,
  );
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

  test("mini-xarita chizish arzon tushadi", () {
    final world = filledWorld();
    const size = Size(96, 96);

    var rects = 0;
    void frame() {
      final rec = ui.PictureRecorder();
      rects = MiniMap.paintTerritories(
        ui.Canvas(rec, Offset.zero & size),
        world.grid,
        world.colorIndexById,
        size,
      );
      rec.endRecording().dispose();
    }

    frame();
    expect(rects, greaterThan(100), reason: 'xarita bo\'sh bo\'lmasligi kerak');

    const frames = 200;
    final sw = Stopwatch()..start();
    for (var i = 0; i < frames; i++) {
      frame();
    }
    sw.stop();
    final us = sw.elapsedMicroseconds / frames;

    // Mini-xarita HUD bilan birga, sekundiga ~8 marta qayta chiziladi —
    // ya'ni har kadrda emas. Shunga qaramay kadr byudjetiga sig'sin.
    // ignore: avoid_print
    print(
      'mini-xarita: $rects to\'rtburchak, ${us.toStringAsFixed(1)} µs/chizish '
      '(sekundiga ~8 marta)',
    );
    expect(us, lessThan(4000));
  });

  test("arena panjarasini chizish kadr byudjetiga sig'adi", () {
    final world = filledWorld();
    final visible = busiestView(world);
    final map = Rect.fromLTWH(
      0,
      0,
      world.grid.width * kCellSize,
      world.grid.height * kCellSize,
    );

    final minorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    var lines = 0;
    void frame() {
      final (minor, major) = BoardBackground.buildGridPoints(visible, map);
      lines = (minor.length + major.length) ~/ 4;
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec, visible);
      canvas.drawRawPoints(ui.PointMode.lines, minor, minorPaint);
      canvas.drawRawPoints(ui.PointMode.lines, major, majorPaint);
      rec.endRecording().dispose();
    }

    frame();
    expect(lines, greaterThan(50), reason: 'panjara chizilishi kerak');

    const frames = 600;
    final sw = Stopwatch()..start();
    for (var i = 0; i < frames; i++) {
      frame();
    }
    sw.stop();
    final us = sw.elapsedMicroseconds / frames;

    // ignore: avoid_print
    print('arena panjarasi: $lines chiziq, ${us.toStringAsFixed(1)} µs/kadr');
    expect(us, lessThan(2000));
  });

  test('avatarlarni chizish kadr byudjetiga sig\'adi', () {
    final world = filledWorld();
    final shapes = TerritoryShapes(world.grid, kCellSize);
    final painter = AvatarPainter();

    // Eng yomon holat o'lchanadi: hamma o'yinchining avatari bir kadrda.
    // Haqiqiy o'yinda ekranga 2-3 ta hudud sig'adi, shuning uchun bu
    // yuqori chegara.
    final everything = Rect.fromLTWH(
      0,
      0,
      world.grid.width * kCellSize,
      world.grid.height * kCellSize,
    );
    final rec0 = ui.PictureRecorder();
    shapes.render(ui.Canvas(rec0, everything), world.players, everything);
    rec0.endRecording().dispose();

    final slots = <int, AvatarSlot>{
      for (final p in world.players)
        if (shapes.slotOf(p.id) != null) p.id: shapes.slotOf(p.id)!,
    };
    expect(
      slots.length,
      greaterThan(10),
      reason: 'tirik o\'yinchilarning hammasida avatar bo\'lishi kerak',
    );

    void frame() {
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec, everything);
      for (final p in world.players) {
        final slot = slots[p.id];
        if (slot == null) continue;
        painter.paint(canvas, p.avatar, slot.center, slot.size);
      }
      rec.endRecording().dispose();
    }

    frame(); // birinchi kadrda paragraflar keshlanadi

    const frames = 600;
    final sw = Stopwatch()..start();
    for (var i = 0; i < frames; i++) {
      frame();
    }
    sw.stop();
    final us = sw.elapsedMicroseconds / frames;

    // ignore: avoid_print
    print('avatarlar: ${slots.length} dona, ${us.toStringAsFixed(1)} µs/kadr');
    expect(us, lessThan(2000));
  });

  test("keshlangan hudud shakllarini chizish kadr byudjetiga sig'adi", () {
    final world = filledWorld();
    final shapes = TerritoryShapes(world.grid, kCellSize);

    final visible = busiestView(world);

    double drawOnce() {
      final sw = Stopwatch()..start();
      final rec = ui.PictureRecorder();
      shapes.render(ui.Canvas(rec, visible), world.players, visible);
      rec.endRecording().dispose();
      sw.stop();
      return sw.elapsedMicroseconds.toDouble();
    }

    final firstUs = drawOnce();
    final rebuilt = shapes.lastRebuildCount;

    const frames = 600;
    final sw = Stopwatch()..start();
    for (var i = 0; i < frames; i++) {
      final rec = ui.PictureRecorder();
      shapes.render(ui.Canvas(rec, visible), world.players, visible);
      rec.endRecording().dispose();
    }
    sw.stop();
    final cachedUs = sw.elapsedMicroseconds / frames;

    // ignore: avoid_print
    print(
      'hudud shakllari: birinchi kadr ${firstUs.toStringAsFixed(0)} µs '
      '($rebuilt shakl yozildi), keshdan ${cachedUs.toStringAsFixed(1)} µs/kadr',
    );

    expect(shapes.lastRebuildCount, 0, reason: 'keyin qayta yozilmaydi');
    expect(cachedUs, lessThan(2000));
    shapes.dispose();
  });

  test("bitta shaklni qayta yozish kadr byudjetiga sig'adi", () {
    final world = filledWorld();
    final shapes = TerritoryShapes(world.grid, kCellSize);
    // Eng katta hududli o'yinchini olamiz — eng og'ir holat.
    final biggest = world.leaderboard().first;
    final b = world.grid.boundsOf(biggest.id)!;
    final visible = Rect.fromLTRB(
      b.$1 * kCellSize,
      b.$2 * kCellSize,
      (b.$3 + 1) * kCellSize,
      (b.$4 + 1) * kCellSize,
    );

    double renderOnce() {
      final sw = Stopwatch()..start();
      final rec = ui.PictureRecorder();
      shapes.render(ui.Canvas(rec, visible), [biggest], visible);
      rec.endRecording().dispose();
      sw.stop();
      return sw.elapsedMicroseconds.toDouble();
    }

    // Isitish.
    for (var i = 0; i < 20; i++) {
      world.grid.setOwner(b.$1, b.$2, biggest.id);
      world.grid.setOwner(b.$1, b.$2, 0);
      renderOnce();
    }

    var worst = 0.0;
    for (var i = 0; i < 20; i++) {
      // Hududni "o'zgartirib" keshni eskirtiramiz.
      world.grid.setOwner(b.$1, b.$2, biggest.id);
      final us = renderOnce();
      if (us > worst) worst = us;
    }

    final area = (b.$3 - b.$1 + 1) * (b.$4 - b.$2 + 1);
    // ignore: avoid_print
    print(
      'eng katta hudud shaklini qayta yozish: '
      '${worst.toStringAsFixed(0)} µs '
      '(${world.grid.territoryOf(biggest.id)} katak, soha $area)',
    );
    expect(worst, lessThan(16000));
    shapes.dispose();
  });

  test("harakat paytida kam shakl qayta yoziladi", () {
    final world = filledWorld();
    final shapes = TerritoryShapes(world.grid, kCellSize);

    const dt = 1 / 60;
    var total = 0;
    var worst = 0;
    const frames = 900; // 15 soniya

    for (var i = 0; i < frames; i++) {
      world.update(dt);
      final human = world.human;
      final visible = Rect.fromCenter(
        center: Offset(human.x * kCellSize, human.y * kCellSize),
        width: kVisibleCells * kCellSize,
        height: kVisibleCells * (16 / 9) * kCellSize,
      );
      final rec = ui.PictureRecorder();
      shapes.render(ui.Canvas(rec, visible), world.players, visible);
      rec.endRecording().dispose();
      total += shapes.lastRebuildCount;
      if (shapes.lastRebuildCount > worst) worst = shapes.lastRebuildCount;
    }

    // ignore: avoid_print
    print(
      "shakl qayta yozish: o'rtacha ${(total / frames).toStringAsFixed(2)}/kadr, "
      'eng ko\'pi $worst',
    );
    expect(total / frames, lessThan(4));
    shapes.dispose();
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
