import 'package:color_land/ui/theme/arcade.dart';
import 'package:color_land/ui/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: Arcade.themeData(),
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('tugma bosilganda chaqiriladi', (tester) async {
    var taps = 0;
    await pump(tester, GameButton(label: 'Boshlash', onPressed: () => taps++));
    await tester.tap(find.byType(GameButton));
    expect(taps, 1);
  });

  testWidgets("o'chirilgan tugma bosilmaydi", (tester) async {
    var taps = 0;
    await pump(
      tester,
      GameButton(label: 'Boshlash', enabled: false, onPressed: () => taps++),
    );
    await tester.tap(find.byType(GameButton));
    expect(taps, 0, reason: "o'chirilgan tugma ishlamasligi kerak");
  });

  testWidgets('bosilganda tugma pastga suriladi', (tester) async {
    await pump(tester, GameButton(label: 'Boshlash', onPressed: () {}));
    final finder = find.byType(AnimatedContainer).first;

    double shift() =>
        (tester.widget<AnimatedContainer>(finder).transform as Matrix4)
            .getTranslation()
            .y;

    expect(shift(), 0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GameButton)),
    );
    await tester.pump();
    expect(shift(), greaterThan(0), reason: 'bosilganda pastga tushadi');

    await gesture.up();
    await tester.pump();
    expect(shift(), 0, reason: "qo'yib yuborilganda qaytadi");
  });

  testWidgets('tugma yozuvi katta harflarda ko\'rinadi', (tester) async {
    await pump(tester, GameButton(label: 'Boshlash', onPressed: () {}));
    expect(find.text('BOSHLASH'), findsOneWidget);
  });

  testWidgets('tanlov chiplari tanlanganini qaytaradi', (tester) async {
    String? picked;
    await pump(
      tester,
      ChoiceChips<String>(
        values: const ['Oson', "O'rta", 'Qiyin'],
        selected: "O'rta",
        labelOf: (v) => v,
        onSelected: (v) => picked = v,
      ),
    );
    await tester.tap(find.text('Qiyin'));
    expect(picked, 'Qiyin');
  });
}
