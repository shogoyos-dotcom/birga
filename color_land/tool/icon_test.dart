// Ilova ikonkasini kod bilan chizadi va barcha kerakli o'lchamlarda saqlaydi.
// Ishga tushirish: flutter test tool/icon_test.dart
//
// Chiqadigan fayllar:
//   android/app/src/main/res/mipmap-*/ic_launcher.png  — klassik ikonka
//   android/app/src/main/res/drawable-xxxhdpi/ic_launcher_*.png — adaptiv
//   build/play/icon_512.png     — Google Play do'kon ikonkasi
//   build/play/feature_1024x500.png — Play "feature graphic"
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ikonka fonining rangi (adaptiv ikonka uchun ham shu).
const Color kIconBg = Color(0xFF2E7BFF);

/// Ikonka belgisi: egallangan hudud va undan chiqib ketayotgan o'yinchi.
///
/// `size` — tuvalning tomoni, `inset` — belgini kichraytirish darajasi
/// (adaptiv ikonkada xavfsiz zona uchun kerak).
void drawMark(
  ui.Canvas canvas,
  double size, {
  double inset = 0.0,
  bool monochrome = false,
}) {
  final fill = Paint()..isAntiAlias = true;
  final unit = size / 12;
  final scale = 1 - inset;

  canvas.save();
  canvas.translate(size / 2, size / 2);
  canvas.scale(scale);
  canvas.translate(-size / 2, -size / 2);

  RRect block(double cx, double cy, double w, double h, double r) =>
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx * unit, cy * unit, w * unit, h * unit),
        Radius.circular(r * unit),
      );

  // Iz — hududdan chiqib ketayotgan yo'lak. Hudud ustidan chiziladi,
  // shuning uchun avval qo'yiladi: iz hududning tagidan chiqqandek bo'ladi.
  fill.color = monochrome ? Colors.white : const Color(0xFFBBD4FF);
  canvas.drawRRect(block(2.4, 7.5, 5.4, 2.0, 1.0), fill);

  // Egallangan hudud — zinapoyasimon shakl.
  fill.color = Colors.white;
  canvas.drawRRect(block(2, 2, 5, 5, 1.1), fill);
  canvas.drawRRect(block(5.6, 4.4, 4.4, 4.4, 1.1), fill);

  // O'yinchi kvadrati — sariq, oq halqa bilan.
  if (monochrome) {
    // Mavzuli ikonkada rang yo'q — o'yinchini "teshik" bilan ajratamiz.
    canvas.drawRRect(
      block(1.3, 6.9, 3.3, 3.3, 1.0),
      Paint()
        ..isAntiAlias = true
        ..blendMode = BlendMode.clear,
    );
    canvas.drawRRect(
      block(1.3, 6.9, 3.3, 3.3, 1.0),
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.5
        ..color = Colors.white,
    );
  } else {
    fill.color = const Color(0xFFFFD60A);
    canvas.drawRRect(block(1.3, 6.9, 3.3, 3.3, 1.0), fill);
    canvas.drawRRect(
      block(1.3, 6.9, 3.3, 3.3, 1.0),
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.5
        ..color = Colors.white,
    );
  }

  canvas.restore();
}

Future<void> savePng(
  WidgetTester tester,
  String path,
  int width,
  int height,
  void Function(ui.Canvas canvas) paint,
) async {
  await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    paint(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    picture.dispose();
    image.dispose();
  });
}

void main() {
  testWidgets('ikonkalarni chizish', (tester) async {
    const res = 'android/app/src/main/res';

    // 1. Klassik launcher ikonkalari — fon + belgi, yumaloq burchak.
    const densities = <String, int>{
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };
    for (final entry in densities.entries) {
      final px = entry.value;
      await savePng(tester, '$res/${entry.key}/ic_launcher.png', px, px, (c) {
        final size = px.toDouble();
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size, size),
            Radius.circular(size * 0.22),
          ),
          Paint()..color = kIconBg,
        );
        drawMark(c, size, inset: 0.12);
      });
    }

    // 2. Adaptiv ikonka qatlamlari — 432x432 = 108dp xxxhdpi da.
    // Belgi xavfsiz zonada qoladi (108dp tuvalning ~63dp si).
    await savePng(
      tester,
      '$res/drawable-xxxhdpi/ic_launcher_foreground.png',
      432,
      432,
      (c) => drawMark(c, 432, inset: 0.42),
    );

    // 3. Ishga tushish ekranidagi belgi — 96dp, har bir zichlik uchun.
    // Zichliklarsiz qo'yilsa Android uni mdpi deb hisoblab ulkan qilib
    // cho'zadi, shuning uchun har biri alohida chiqariladi.
    const splash = <String, int>{
      'drawable-mdpi': 96,
      'drawable-hdpi': 144,
      'drawable-xhdpi': 192,
      'drawable-xxhdpi': 288,
      'drawable-xxxhdpi': 384,
    };
    for (final entry in splash.entries) {
      final px = entry.value;
      await savePng(tester, '$res/${entry.key}/splash_mark.png', px, px, (c) {
        drawMark(c, px.toDouble());
      });
    }

    // 4. Monoxrom qatlam — Android 13+ "mavzuli ikonka" uchun.
    // Faqat shakl kerak: hammasi oq, fon shaffof.
    await savePng(
      tester,
      '$res/drawable-xxxhdpi/ic_launcher_monochrome.png',
      432,
      432,
      (c) => drawMark(c, 432, inset: 0.42, monochrome: true),
    );

    // 5. Google Play do'kon ikonkasi — 512x512, shaffofliksiz.
    await savePng(tester, 'build/play/icon_512.png', 512, 512, (c) {
      c.drawRect(const Rect.fromLTWH(0, 0, 512, 512), Paint()..color = kIconBg);
      drawMark(c, 512, inset: 0.12);
    });

    // 6. Play "feature graphic" — 1024x500.
    await savePng(tester, 'build/play/feature_1024x500.png', 1024, 500, (c) {
      c.drawRect(
        const Rect.fromLTWH(0, 0, 1024, 500),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF2E7BFF), Color(0xFF6C7BFF)],
          ).createShader(const Rect.fromLTWH(0, 0, 1024, 500)),
      );
      // Fon bezagi — tasodifiy emas, oldindan belgilangan kvadratlar.
      final rng = math.Random(7);
      final deco = Paint()..color = Colors.white.withValues(alpha: 0.08);
      for (var i = 0; i < 26; i++) {
        final s = 30.0 + rng.nextInt(60);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rng.nextDouble() * 1024,
              rng.nextDouble() * 500,
              s,
              s,
            ),
            const Radius.circular(10),
          ),
          deco,
        );
      }
      c.save();
      c.translate(90, 90);
      drawMark(c, 320);
      c.restore();

      final builder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(fontSize: 86, fontWeight: FontWeight.w900),
            )
            ..pushStyle(ui.TextStyle(color: Colors.white))
            ..addText('COLOR LAND');
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 560));
      c.drawParagraph(paragraph, const Offset(450, 200));
    });

    for (final path in [
      '$res/mipmap-xxxhdpi/ic_launcher.png',
      '$res/drawable-xxxhdpi/ic_launcher_monochrome.png',
      '$res/drawable-xxhdpi/splash_mark.png',
      '$res/drawable-xxxhdpi/ic_launcher_foreground.png',
      'build/play/icon_512.png',
      'build/play/feature_1024x500.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
