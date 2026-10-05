import 'dart:math' as math;

import 'package:color_land/game/logic/game_grid.dart';
import 'package:color_land/game/logic/territory_capture.dart';
import 'package:flutter_test/flutter_test.dart';

/// `pattern` dagi har bir belgi bir katak:
///   '.' — bo'sh, '#' — 1-o'yinchi hududi, raqam — shu ID ning hududi.
GameGrid gridFrom(List<String> pattern) {
  final grid = GameGrid(pattern.first.length, pattern.length);
  for (var y = 0; y < pattern.length; y++) {
    for (var x = 0; x < pattern[y].length; x++) {
      final ch = pattern[y][x];
      if (ch == '.') continue;
      grid.setOwner(x, y, ch == '#' ? 1 : int.parse(ch));
    }
  }
  return grid;
}

List<String> dump(GameGrid grid) {
  return List<String>.generate(grid.height, (y) {
    final sb = StringBuffer();
    for (var x = 0; x < grid.width; x++) {
      final o = grid.ownerAt(x, y);
      sb.write(o == 0 ? '.' : '$o');
    }
    return sb.toString();
  });
}

List<int> trailIndices(GameGrid grid, int id, List<(int, int)> cells) {
  final out = <int>[];
  for (final (x, y) in cells) {
    final i = grid.index(x, y);
    grid.setTrailIndex(i, id);
    out.add(i);
  }
  return out;
}

/// Sodda, sekin, lekin aniq mos yozuvlar algoritmi: butun xaritani
/// skanerlaydi. Tezlashtirilgan `TerritoryCapturer` shu bilan bir xil
/// natija berishi kerak.
List<int> referenceCapture(GameGrid grid, int playerId) {
  final w = grid.width;
  final h = grid.height;
  final reached = List<bool>.filled(w * h, false);
  final queue = <int>[];

  void push(int i) {
    if (!reached[i] && grid.owner[i] != playerId) {
      reached[i] = true;
      queue.add(i);
    }
  }

  for (var x = 0; x < w; x++) {
    push(x);
    push((h - 1) * w + x);
  }
  for (var y = 0; y < h; y++) {
    push(y * w);
    push(y * w + w - 1);
  }
  for (var k = 0; k < queue.length; k++) {
    final i = queue[k];
    final x = i % w;
    final y = i ~/ w;
    if (x > 0) push(i - 1);
    if (x < w - 1) push(i + 1);
    if (y > 0) push(i - w);
    if (y < h - 1) push(i + w);
  }

  final out = <int>[];
  for (var i = 0; i < w * h; i++) {
    if (!reached[i] && grid.owner[i] != playerId) out.add(i);
  }
  return out;
}

void main() {
  group('flood fill — hudud egallash', () {
    test('iz kataklari o\'yinchiga o\'tadi', () {
      final grid = gridFrom(const [
        '#####',
        '#####',
        '.....',
        '.....',
        '.....',
      ]);
      final trail = trailIndices(grid, 1, [(0, 2), (1, 2)]);
      final res = TerritoryCapturer(grid).capture(1, trail);

      expect(grid.ownerAt(0, 2), 1);
      expect(grid.ownerAt(1, 2), 1);
      expect(grid.trailAt(0, 2), 0, reason: 'iz belgisi tozalanadi');
      expect(res.count, 2);
    });

    test('iz bilan o\'ralgan ichki kataklar ham egallanadi', () {
      // Yuqori qatori o'yinchining, iz esa pastga tushib qaytib keladi:
      // o'rtadagi bo'sh kataklar o'ralib qoladi.
      final grid = gridFrom(const [
        '#####',
        '.....',
        '.....',
        '.....',
        '.....',
      ]);
      final trail = trailIndices(grid, 1, [
        (0, 1),
        (0, 2),
        (0, 3),
        (1, 3),
        (2, 3),
        (3, 3),
        (4, 3),
        (4, 2),
        (4, 1),
      ]);
      final res = TerritoryCapturer(grid).capture(1, trail);

      expect(dump(grid), const ['11111', '11111', '11111', '11111', '.....']);
      expect(res.count, 9 + 6);
    });

    test('tashqaridagi bo\'sh kataklar tegilmaydi', () {
      final grid = gridFrom(const [
        '.......',
        '.#####.',
        '.#...#.',
        '.#####.',
        '.......',
      ]);
      // Ichidagi 3 katak allaqachon o'ralgan — hech qanday iz bo'lmasa ham
      // flood fill ularni egallaydi, tashqarisi esa bo'sh qoladi.
      final res = TerritoryCapturer(grid).capture(1, const []);

      expect(dump(grid), const [
        '.......',
        '.11111.',
        '.11111.',
        '.11111.',
        '.......',
      ]);
      expect(res.count, 3);
    });

    test(
      'o\'ralgan raqib hududi egallanadi va kimdan olingani qayd etiladi',
      () {
        final grid = gridFrom(const [
          '.......',
          '.#####.',
          '.#222#.',
          '.#####.',
          '.......',
        ]);
        final res = TerritoryCapturer(grid).capture(1, const []);

        expect(dump(grid)[2], '.11111.');
        expect(res.takenFrom[2], 3);
        expect(grid.territoryOf(2), 0);
      },
    );

    test('o\'ralmagan raqib hududi tegilmaydi', () {
      final grid = gridFrom(const [
        '.......',
        '.####..',
        '.#..2..',
        '.####..',
        '.......',
      ]);
      final res = TerritoryCapturer(grid).capture(1, const []);

      expect(grid.ownerAt(4, 2), 2, reason: 'ochiq joydan yetib boriladi');
      expect(res.takenFrom.containsKey(2), isFalse);
    });

    test('xarita chetiga tiralgan hudud ham o\'rab oladi', () {
      // Chap chet bilan birga yopilgan "C" shakli: ichi egallanishi kerak.
      final grid = gridFrom(const ['####.', '#...#', '#...#', '####.']);
      final res = TerritoryCapturer(grid).capture(1, const []);

      expect(dump(grid), const ['1111.', '11111', '11111', '1111.']);
      expect(res.count, 6);
    });

    test('butun chet o\'yinchiga tegishli bo\'lsa hammasi egallanadi', () {
      final grid = gridFrom(const ['####', '#..#', '#22#', '####']);
      final res = TerritoryCapturer(grid).capture(1, const []);

      expect(dump(grid), const ['1111', '1111', '1111', '1111']);
      expect(res.takenFrom[2], 2);
    });

    test('hudud hisoblagichi to\'g\'ri yuritiladi', () {
      final grid = gridFrom(const [
        '.......',
        '.#####.',
        '.#222#.',
        '.#####.',
        '.......',
      ]);
      expect(grid.territoryOf(1), 12);
      expect(grid.territoryOf(2), 3);

      TerritoryCapturer(grid).capture(1, const []);

      expect(grid.territoryOf(1), 15);
      expect(grid.territoryOf(2), 0);
      expect(grid.territoryOf(0), 7 * 5 - 15);
      expect(grid.percentOf(1), closeTo(15 * 100 / 35, 1e-9));
    });

    test('o\'zgargan chunklar belgilanadi', () {
      final grid = GameGrid(40, 40, chunkCells: 16);
      grid.dirtyChunks.clear();
      grid.setOwner(0, 0, 1);
      grid.setOwner(20, 20, 1);
      expect(grid.dirtyChunks, containsAll(<int>[0, grid.chunksX + 1]));
    });

    test(
      'tezlashtirilgan versiya sodda algoritm bilan bir xil natija beradi',
      () {
        // Tasodifiy, lekin takrorlanadigan holatlar: o'yinchi hududi,
        // raqib hududi va izlar aralashgan panjara.
        final rng = math.Random(2024);
        for (var round = 0; round < 40; round++) {
          final grid = GameGrid(40, 40);
          // 1-o'yinchiga bir necha to'rtburchak beramiz.
          for (var k = 0; k < 4; k++) {
            final left = rng.nextInt(30);
            final top = rng.nextInt(30);
            final wBlock = 2 + rng.nextInt(8);
            final hBlock = 2 + rng.nextInt(8);
            for (var y = top; y < top + hBlock && y < 40; y++) {
              for (var x = left; x < left + wBlock && x < 40; x++) {
                grid.setOwner(x, y, 1);
              }
            }
          }
          // Raqiblar uchun tasodifiy kataklar.
          for (var k = 0; k < 120; k++) {
            final x = rng.nextInt(40);
            final y = rng.nextInt(40);
            if (grid.ownerAt(x, y) == 0) {
              grid.setOwner(x, y, 2 + rng.nextInt(3));
            }
          }

          final expected = referenceCapture(grid, 1).toSet();
          final actual = TerritoryCapturer(grid).capture(1, const []);

          expect(
            actual.cells.toSet(),
            expected,
            reason: '$round-urinishda natijalar farq qildi',
          );
        }
      },
    );

    test('kattaroq panjarada ham to\'g\'ri va tez ishlaydi', () {
      final grid = GameGrid(150, 150);
      // 1-o'yinchi uchun yopiq ramka chizamiz.
      for (var x = 10; x <= 120; x++) {
        grid.setOwner(x, 10, 1);
        grid.setOwner(x, 120, 1);
      }
      for (var y = 10; y <= 120; y++) {
        grid.setOwner(10, y, 1);
        grid.setOwner(120, y, 1);
      }
      final sw = Stopwatch()..start();
      final res = TerritoryCapturer(grid).capture(1, const []);
      sw.stop();

      expect(res.count, 109 * 109, reason: 'ramka ichidagi hamma katak');
      expect(grid.ownerAt(65, 65), 1);
      expect(grid.ownerAt(5, 5), 0);
      expect(
        sw.elapsedMilliseconds,
        lessThan(120),
        reason: '150x150 flood fill bir kadrga sig\'ishi kerak',
      );
    });
  });
}
