import 'dart:math' as math;

import 'package:color_land/data/countries.dart';
import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/game/logic/game_grid.dart';
import 'package:color_land/game/logic/match.dart';
import 'package:color_land/game/logic/player_profile.dart';
import 'package:color_land/game/render/shape_painter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flood_fill_test.dart' show gridFrom;

void main() {
  group('Avatar', () {
    test('har bir tur saqlanib, qaytib o\'qiladi', () {
      for (final a in <Avatar>[
        const Avatar.emoji('🦊'),
        const Avatar.figure(7),
        const Avatar.flag('UZ'),
      ]) {
        expect(Avatar.decode(a.encode()), a, reason: a.encode());
      }
    });

    test('buzuq yoki yo\'q qiymat standart avatarga tushadi', () {
      expect(Avatar.decode(null), Avatar.defaultAvatar);
      expect(Avatar.decode(''), Avatar.defaultAvatar);
      expect(Avatar.decode('allaqanday-matn'), Avatar.defaultAvatar);
      // Noma'lum tur ham yiqitmasligi kerak.
      expect(Avatar.decode('rasm:1').kind, AvatarKind.figure);
    });

    test('bayroq kodi emoji bayrog\'iga aylanadi', () {
      // UZ -> U+1F1FA U+1F1FF.
      expect(const Avatar.flag('UZ').glyph.runes.toList(), <int>[
        0x1F1FA,
        0x1F1FF,
      ]);
      expect(const Avatar.flag('US').glyph, '\u{1F1FA}\u{1F1F8}');
      // Noma'lum kod bo'sh beradi — chizuvchi uni o'tkazib yuboradi.
      expect(const Avatar.flag('XX').glyph, '');
    });

    test('odam tasviri uchun glyph bo\'sh, raqami o\'qiladi', () {
      expect(const Avatar.figure(5).glyph, '');
      expect(const Avatar.figure(5).figureIndex, 5);
      expect(const Avatar.emoji('🔥').figureIndex, 0);
    });
  });

  group('davlatlar', () {
    test('ISO 3166-1 ro\'yxati to\'liq va kodlari to\'g\'ri', () {
      expect(kCountries.length, 249);
      for (final c in kCountries) {
        expect(c.code, matches(RegExp(r'^[A-Z]{2}$')), reason: c.name);
        expect(c.name, isNotEmpty);
        expect(c.flag.runes.length, 2, reason: c.code);
      }
      // Kodlar takrorlanmasin.
      expect(kCountries.map((c) => c.code).toSet().length, 249);
    });

    test('izlash nom va kod bo\'yicha ishlaydi', () {
      expect(searchCountries('uzb').single.code, 'UZ');
      expect(searchCountries('UZ').first.code, 'UZ');
      expect(searchCountries('  ').length, 249);
      expect(searchCountries('bunday davlat yo\'q'), isEmpty);
    });

    test('kod bo\'yicha topish katta-kichik harfga bog\'liq emas', () {
      expect(countryByCode('uz')?.name, 'Uzbekistan');
      expect(countryByCode(null), isNull);
      expect(countryByCode('ZZ'), isNull);
    });
  });

  group('taxallus', () {
    test('bo\'sh nom standart nomga aylanadi', () {
      expect(PlayerProfile.sanitize('', 'Siz'), 'Siz');
      expect(PlayerProfile.sanitize('   ', 'Siz'), 'Siz');
    });

    test('uzun nom qirqiladi, probellar olinadi', () {
      expect(PlayerProfile.sanitize('  Alisher  ', 'Siz'), 'Alisher');
      final long = PlayerProfile.sanitize('A' * 50, 'Siz');
      expect(long.length, PlayerProfile.maxNicknameLength);
    });
  });

  group('avatar joyi', () {
    /// `#` — 1-o'yinchi hududi.
    (int, int, int, int) boundsFor(GameGrid g) => g.boundsOf(1)!;

    test('to\'rtburchak hududning markaziga tushadi', () {
      final grid = gridFrom(<String>[
        '........',
        '.######.',
        '.######.',
        '.######.',
        '.######.',
        '........',
      ]);
      final slot = TerritoryShapes.computeAvatarSlot(
        grid,
        1,
        boundsFor(grid),
        10,
      );
      expect(slot, isNotNull);
      // 1..6 x 1..4 → markaz (3.5, 2.5) katak, ya'ni 35, 25 dunyo birligida.
      expect(slot!.center.dx, closeTo(35, 10));
      expect(slot.center.dy, closeTo(25, 10));
      // Bo'yi 4 katak → eng qalin nuqtada masofa 2, diametr 3 katak.
      expect(slot.size, closeTo(3 * 10 * TerritoryShapes.avatarFit, 0.01));
    });

    test('markaz begona katakka tushsa, o\'z hududiga suriladi', () {
      // Yarim oysimon hudud: geometrik markaz ichida bo'sh joy.
      final grid = gridFrom(<String>[
        '#########',
        '#########',
        '###...###',
        '###...###',
        '###...###',
        '#########',
        '#########',
      ]);
      final slot = TerritoryShapes.computeAvatarSlot(
        grid,
        1,
        boundsFor(grid),
        10,
      );
      expect(slot, isNotNull);
      final cx = (slot!.center.dx / 10).floor();
      final cy = (slot.center.dy / 10).floor();
      expect(
        grid.ownerAt(cx, cy),
        1,
        reason: 'avatar markazi o\'z hududida bo\'lishi kerak',
      );
    });

    test('ingichka hududda avatar kichikroq bo\'ladi', () {
      // Keng, lekin yupqa lenta.
      final thin = gridFrom(<String>[
        '............',
        '############',
        '############',
        '############',
        '............',
      ]);
      // Shuncha katakli, lekin to'la kvadrat.
      final fat = gridFrom(<String>[
        '........',
        '.######.',
        '.######.',
        '.######.',
        '.######.',
        '.######.',
        '.######.',
        '........',
      ]);
      final thinSlot = TerritoryShapes.computeAvatarSlot(
        thin,
        1,
        boundsFor(thin),
        10,
      )!;
      final fatSlot = TerritoryShapes.computeAvatarSlot(
        fat,
        1,
        boundsFor(fat),
        10,
      )!;
      // Lenta kengligi avatarga ta'sir qilmaydi — faqat qalinligi.
      expect(thinSlot.size, lessThan(fatSlot.size));
    });

    test('kichik hududda avatar chizilmaydi', () {
      final grid = gridFrom(<String>['.....', '.##..', '.##..', '.....']);
      expect(
        TerritoryShapes.computeAvatarSlot(grid, 1, boundsFor(grid), 10),
        isNull,
        reason: '4 katak hududga avatar sig\'maydi',
      );
    });

    test('hududsiz o\'yinchi uchun joy yo\'q', () {
      final grid = gridFrom(<String>['..', '..']);
      expect(
        TerritoryShapes.computeAvatarSlot(grid, 1, (0, 0, 1, 1), 10),
        isNull,
      );
    });
  });

  group('o\'yin boshlanishi', () {
    test('o\'yinchi profildagi avatarni oladi, botlar tasodifiy', () {
      final sim = createMatch(
        config: const GameConfig(),
        playerColorIndex: 0,
        playerName: 'Men',
        availableColors: 8,
        playerAvatar: const Avatar.flag('UZ'),
        random: math.Random(7),
      );
      final human = sim.players.firstWhere((p) => !p.isBot);
      expect(human.avatar, const Avatar.flag('UZ'));
      expect(human.name, 'Men');

      final bots = sim.players.where((p) => p.isBot).toList();
      expect(bots, isNotEmpty);
      // Botlarning avatarlari hammasi bir xil bo'lib qolmasin.
      expect(bots.map((b) => b.avatar).toSet().length, greaterThan(1));
    });

    test('tasodifiy avatar har uchala turdan chiqadi', () {
      final rng = math.Random(3);
      final kinds = <AvatarKind>{};
      for (var i = 0; i < 200; i++) {
        kinds.add(randomAvatar(rng).kind);
      }
      expect(kinds, AvatarKind.values.toSet());
    });
  });
}
