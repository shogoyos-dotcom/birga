import 'dart:math' as math;
import 'dart:typed_data';

import 'package:color_land/data/capitals.dart';
import 'package:color_land/data/world_map.dart';
import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/game/logic/game_grid.dart';
import 'package:color_land/game/logic/game_world.dart';
import 'package:color_land/game/logic/match.dart';
import 'package:color_land/game/logic/territory_capture.dart';
import 'package:flutter_test/flutter_test.dart';

/// `pattern` dagi `~` — suv, `.` — bo'sh quruqlik, raqam — o'sha ID hududi.
GameGrid mapFrom(List<String> pattern) {
  final w = pattern.first.length;
  final h = pattern.length;
  final land = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      land[y * w + x] = pattern[y][x] == '~' ? 0 : 1;
    }
  }
  final grid = GameGrid(w, h, land: land);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final ch = pattern[y][x];
      if (ch == '~' || ch == '.') continue;
      grid.setOwner(x, y, int.parse(ch));
    }
  }
  return grid;
}

void main() {
  group('dunyo xaritasi ma\'lumoti', () {
    test('niqob o\'lchami va quruqlik miqdori to\'g\'ri', () {
      final land = decodeWorldLand();
      expect(land.length, kWorldWidth * kWorldHeight);
      final count = land.fold<int>(0, (a, b) => a + b);
      expect(count, kWorldLandCells);
      // Yer yuzasining ~30% i quruqlik (Antarktidasiz).
      final share = count / land.length;
      expect(share, greaterThan(0.2));
      expect(share, lessThan(0.4));
    });

    test('poytaxtlar xarita ichida va quruqlikda turadi', () {
      final land = decodeWorldLand();
      expect(kCapitals, hasLength(236));
      for (final c in kCapitals) {
        expect(c.x, inInclusiveRange(0, kWorldWidth - 1), reason: c.name);
        expect(c.y, inInclusiveRange(0, kWorldHeight - 1), reason: c.name);
        expect(
          land[c.y * kWorldWidth + c.x],
          1,
          reason: '${c.name} suvda qolib ketgan',
        );
      }
    });

    test('poytaxtlar bir katakda ustma-ust turmaydi', () {
      final spots = kCapitals.map((c) => '${c.x},${c.y}').toSet();
      expect(spots.length, kCapitals.length);
    });

    test('poytaxtlar aholisi bo\'yicha saralangan', () {
      for (var i = 1; i < kCapitals.length; i++) {
        expect(
          kCapitals[i - 1].population,
          greaterThanOrEqualTo(kCapitals[i].population),
        );
      }
    });

    test('mashhur poytaxtlar to\'g\'ri joyda', () {
      Capital find(String name) => kCapitals.firstWhere((c) => c.name == name);
      // Toshkent Sharqiy yarim sharda va shimolda.
      final tashkent = find('Tashkent');
      expect(tashkent.x, greaterThan(kWorldWidth / 2));
      expect(tashkent.y, lessThan(kWorldHeight / 2));
      // Buenos Aires — g'arbda va janubda.
      final ba = find('Buenos Aires');
      expect(ba.x, lessThan(kWorldWidth / 2));
      expect(ba.y, greaterThan(kWorldHeight / 2));
      // Toshkent Buenos Airesdan sharqroqda va shimolroqda.
      expect(tashkent.x, greaterThan(ba.x));
      expect(tashkent.y, lessThan(ba.y));
    });
  });

  group('suv — to\'siq', () {
    test('foiz quruqlikka nisbatan hisoblanadi', () {
      final grid = mapFrom(<String>['~~~~', '~11~', '~11~', '~~~~']);
      expect(grid.landCells, 4);
      expect(grid.territoryOf(1), 4);
      expect(grid.percentOf(1), 100, reason: 'butun quruqlik egallangan');
    });

    test('o\'ralgan ko\'l egallanmaydi', () {
      // 1-o'yinchi halqa chizgan, ichida ko'l bor.
      final grid = mapFrom(<String>[
        '.....',
        '.111.',
        '.1~1.',
        '.111.',
        '.....',
      ]);
      TerritoryCapturer(grid).capture(1, const <int>[]);
      expect(grid.ownerAt(2, 2), 0, reason: 'ko\'l ko\'l bo\'lib qoladi');
      expect(grid.territoryOf(1), 8);
    });

    test('o\'ralgan quruqlik egallanadi', () {
      final grid = mapFrom(<String>[
        '.....',
        '.111.',
        '.1.1.',
        '.111.',
        '.....',
      ]);
      TerritoryCapturer(grid).capture(1, const <int>[]);
      expect(grid.ownerAt(2, 2), 1);
      expect(grid.territoryOf(1), 9);
    });

    test('suv katagiga kirib bo\'lmaydi', () {
      final grid = mapFrom(<String>['~.~']);
      expect(grid.playable(0, 0), isFalse);
      expect(grid.playable(1, 0), isTrue);
      expect(grid.playable(2, 0), isFalse);
    });
  });

  group('dunyo xaritasidagi o\'yin', () {
    test('o\'yinchilar quruqlikda tug\'iladi', () {
      final world = createMatch(
        config: const GameConfig(botCount: 15),
        playerColorIndex: 0,
        playerName: 'Siz',
        availableColors: 16,
        random: math.Random(5),
      );
      for (final p in world.players) {
        expect(p.alive, isTrue, reason: '${p.name} joy topa olmadi');
        expect(
          world.grid.playable(p.cx, p.cy),
          isTrue,
          reason: '${p.name} suvda tug\'ildi',
        );
      }
    });

    test('o\'yinchi okeanga chiqib keta olmaydi', () {
      final world = GameWorld(
        config: const GameConfig(botCount: 0),
        random: math.Random(5),
      );
      final p = world.addPlayer(name: 'P', colorIndex: 0, isBot: false);
      world.spawnAll();

      // Har tomonga uzoq yuramiz — qayerda bo'lsa ham quruqlikda qolsin.
      for (var dir = 0; dir < 8; dir++) {
        p.steerTo(dir * math.pi / 4);
        p.angle = dir * math.pi / 4;
        for (var i = 0; i < 600; i++) {
          world.update(1 / 60);
          if (!p.alive) break;
          expect(
            world.grid.playable(p.cx, p.cy),
            isTrue,
            reason: 'o\'yinchi suvga tushdi: ${p.cx},${p.cy}',
          );
        }
        if (!p.alive) break;
      }
    });

    test('hech qanday hudud suvga tushmaydi', () {
      // Botlar bilan haqiqiy o'yin — hudud o'sadi, egallanadi, o'ladi.
      final world = createMatch(
        config: const GameConfig(botCount: 15),
        playerColorIndex: 0,
        playerName: 'Siz',
        availableColors: 16,
        random: math.Random(9),
      );
      for (var i = 0; i < 60 * 60; i++) {
        world.update(1 / 60);
      }

      final grid = world.grid;
      var owned = 0;
      for (var i = 0; i < grid.owner.length; i++) {
        if (grid.owner[i] == 0) continue;
        owned++;
        expect(grid.isLandIndex(i), isTrue, reason: 'suv egallangan: $i');
      }
      expect(owned, greaterThan(2000), reason: 'o\'yin haqiqatan ketdi');
    });
  });
}
