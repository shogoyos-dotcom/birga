import 'dart:math' as math;

import 'package:color_land/game/render/color_land_game.dart';
import 'package:color_land/ui/widgets/ui_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matnni katta-kichik harfga qaramay topadi.
///
/// Interfeys sarlavhalarni KATTA HARFLARDA ko'rsatadi — bu dizayn
/// qarori, testlar unga bog'lanib qolmasligi kerak.
Finder findText(String text) {
  final needle = text.toLowerCase();
  return find.byWidgetPredicate(
    (w) => w is Text && (w.data ?? '').toLowerCase() == needle,
    description: 'matn "$text" (harf registriga qaramay)',
  );
}

/// Tugmani yozuvi bo'yicha topadi (yozuv ekranda katta harflarda).
Finder findButton(String label) => find.byWidgetPredicate(
  (w) => w is GameButton && w.label == label,
  description: 'tugma "$label"',
);

/// Tugmani yozuvining bir qismi bo'yicha topadi.
Finder findButtonContaining(String part) => find.byWidgetPredicate(
  (w) => w is GameButton && w.label.contains(part),
  description: 'tugma, yozuvida "$part"',
);

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.tap(findButton(label));
  await tester.pumpAndSettle();
}

/// O'yinchini o'z izini kesishga majbur qiladi.
///
/// Chegara endi o'ldirmaydi, shuning uchun testlarda o'lim uchun shu
/// yo'l ishlatiladi: hududdan uzoqlashib, keyin tor aylana chizadi —
/// aylana uzunligi "yangi iz" oynasidan katta bo'lgani uchun o'z iziga
/// tegadi.
Future<void> dieBySelfCross(WidgetTester tester, ColorLandGame game) async {
  const frame = Duration(milliseconds: 16);

  // 1. Hududdan chiqib, uzunroq iz qoldiramiz.
  game.setSteerAngle(-math.pi / 2);
  for (var i = 0; i < 130 && game.sim.human.alive; i++) {
    await tester.pump(frame);
  }

  // 2. Tor aylana: har kadrda yo'nalishni buramiz.
  var angle = -math.pi / 2;
  for (var i = 0; i < 900 && game.sim.human.alive; i++) {
    angle += 0.3;
    game.setSteerAngle(angle);
    await tester.pump(frame);
  }

  // 3. Natija oynasi chiqishi uchun bir necha kadr.
  for (var i = 0; i < 12; i++) {
    await tester.pump(frame);
  }
}
