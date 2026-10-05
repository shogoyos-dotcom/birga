// O'yinning haqiqiy kadrini PNG qilib saqlaydi — qo'lda ko'rib tekshirish uchun.
// Ishga tushirish: flutter test tool/screenshot_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/game/render/color_land_game.dart';
import 'package:color_land/ui/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  testWidgets('skrinshot', (tester) async {
    tester.view
      ..physicalSize = const Size(720, 1280)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: shotKey,
          child: const GameScreen(
            config: GameConfig(gridWidth: 80, gridHeight: 80, botCount: 0),
            colorIndex: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    final game = tester.state<State>(find.byType(GameScreen));
    // ignore: avoid_dynamic_calls
    final ColorLandGame g = (game as dynamic).gameForTest as ColorLandGame;

    // Katta to'rtburchak chizib hudud egallaydi.
    const frame = Duration(milliseconds: 16);
    Future<void> run(double angle, int frames) async {
      g.setSteerAngle(angle);
      for (var i = 0; i < frames; i++) {
        await tester.pump(frame);
      }
    }

    await run(-math.pi / 2, 70); // yuqoriga
    await run(0, 70); // o'ngga
    await run(math.pi / 2, 90); // pastga
    await run(math.pi, 60); // chapga -> hududga qaytadi
    await run(-math.pi / 2, 20);

    await saveFrame(tester, 'build/screenshot.png');
    expect(File('build/screenshot.png').existsSync(), isTrue);
    // ignore: avoid_print
    print('hudud foizi: ${g.sim.grid.percentOf(1).toStringAsFixed(2)}%');
  });
}
