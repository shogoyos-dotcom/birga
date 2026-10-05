import 'package:color_land/game/render/contour.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matndan shakl yasaydi: '#' — ichkari, '.' — tashqari.
bool Function(int, int) shapeFrom(List<String> rows) {
  return (int x, int y) {
    if (y < 0 || y >= rows.length) return false;
    if (x < 0 || x >= rows[y].length) return false;
    return rows[y][x] == '#';
  };
}

/// Halqaning yopiq maydoni (shoelace). Ishorasi yo'nalishni bildiradi.
double signedArea(List<Offset> loop) {
  var sum = 0.0;
  for (var i = 0; i < loop.length; i++) {
    final a = loop[i];
    final b = loop[(i + 1) % loop.length];
    sum += a.dx * b.dy - b.dx * a.dy;
  }
  return sum / 2;
}

void main() {
  group('kontur topish', () {
    test('bitta katak — to\'rt burchakli halqa', () {
      final loops = ContourBuilder.trace(
        shapeFrom(const ['...', '.#.', '...']),
        0,
        0,
        2,
        2,
      );
      expect(loops.length, 1);
      expect(loops.first.length, 4);
      expect(signedArea(loops.first).abs(), 1.0, reason: 'yuzasi 1 katak');
    });

    test('to\'rtburchak — bitta halqa, yuzasi mos keladi', () {
      final loops = ContourBuilder.trace(
        shapeFrom(const ['.....', '.###.', '.###.', '.....']),
        0,
        0,
        4,
        3,
      );
      expect(loops.length, 1);
      expect(signedArea(loops.first).abs(), 6.0, reason: '3x2 = 6 katak');
    });

    test('teshikli shakl — ikki halqa, teskari yo\'nalishda', () {
      final loops = ContourBuilder.trace(
        shapeFrom(const ['.....', '.###.', '.#.#.', '.###.', '.....']),
        0,
        0,
        4,
        4,
      );
      expect(loops.length, 2, reason: 'tashqi chegara va teshik');
      final areas = loops.map(signedArea).toList()..sort();
      // Ishoralar qarama-qarshi bo'lishi shart — nonZero teshikni kesadi.
      expect(areas.first.sign, isNot(areas.last.sign));
      expect(areas.map((a) => a.abs()).reduce((a, b) => a > b ? a : b), 9.0);
      expect(areas.map((a) => a.abs()).reduce((a, b) => a < b ? a : b), 1.0);
    });

    test('ikki ajralgan bo\'lak — ikki halqa', () {
      final loops = ContourBuilder.trace(
        shapeFrom(const ['#.#', '...', '#.#']),
        0,
        0,
        2,
        2,
      );
      expect(loops.length, 4, reason: 'har burchakda bittadan');
    });

    test('bo\'sh shakl — halqa yo\'q', () {
      final loops = ContourBuilder.trace(
        shapeFrom(const ['...', '...']),
        0,
        0,
        2,
        1,
      );
      expect(loops, isEmpty);
    });
  });

  group('silliqlash', () {
    test('bir chiziqdagi nuqtalar olib tashlanadi', () {
      final loops = ContourBuilder.trace(
        shapeFrom(const ['.....', '.###.', '.###.', '.....']),
        0,
        0,
        4,
        3,
      );
      final simplified = ContourBuilder.dropCollinear(loops.first);
      expect(simplified.length, 4, reason: 'to\'rtburchakda 4 ta burchak');
    });

    test('pog\'onali qiya chegara to\'g\'ri chiziqqa aylanadi', () {
      // Zinapoyasimon diagonal — panjarada qiya chegara shunday yotadi.
      final loops = ContourBuilder.trace(
        shapeFrom(const [
          '#.....',
          '##....',
          '###...',
          '####..',
          '#####.',
          '######',
        ]),
        0,
        0,
        5,
        5,
      );
      final corners = ContourBuilder.dropCollinear(loops.first);
      final simplified = ContourBuilder.simplify(corners, 0.8);

      expect(
        simplified.length,
        lessThan(corners.length),
        reason: 'pog\'onalar kamayadi',
      );
      expect(
        simplified.length,
        lessThanOrEqualTo(5),
        reason: 'uchburchakka yaqin: uchta tomon + bir-ikki nuqta',
      );
    });

    test('soddalashtirish kichik shaklni yo\'qotmaydi', () {
      final loops = ContourBuilder.trace(
        shapeFrom(const ['...', '.#.', '...']),
        0,
        0,
        2,
        2,
      );
      final simplified = ContourBuilder.simplify(
        ContourBuilder.dropCollinear(loops.first),
        0.8,
      );
      expect(simplified.length, greaterThanOrEqualTo(3));
      expect(signedArea(simplified).abs(), greaterThan(0.5));
    });

    test('Chaikin nuqtalarni ko\'paytiradi va shaklni saqlaydi', () {
      final square = <Offset>[
        const Offset(0, 0),
        const Offset(4, 0),
        const Offset(4, 4),
        const Offset(0, 4),
      ];
      final smooth = ContourBuilder.smooth(square);
      expect(smooth.length, 16, reason: 'har iteratsiyada ikki barobar');

      // Silliqlangan shakl asl kvadrat ichida qoladi va unchalik kichraymaydi.
      for (final p in smooth) {
        expect(p.dx, inInclusiveRange(0, 4));
        expect(p.dy, inInclusiveRange(0, 4));
      }
      final area = signedArea(smooth).abs();
      expect(area, greaterThan(16 * 0.8), reason: 'yuzasi ko\'p yo\'qolmaydi');
      expect(area, lessThan(16.0));
    });
  });
}
