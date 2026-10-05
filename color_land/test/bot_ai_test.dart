import 'dart:math' as math;

import 'package:color_land/game/logic/bot_ai.dart';
import 'package:color_land/game/logic/difficulty.dart';
import 'package:color_land/game/logic/game_events.dart';
import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/game/logic/game_world.dart';
import 'package:color_land/game/logic/match.dart';
import 'package:color_land/game/render/palette.dart';
import 'package:flutter_test/flutter_test.dart';

GameWorld runMatch({
  required Difficulty difficulty,
  // O'yindagi standart bilan bir xil: kamroq bot bo'lsa xaritada
  // uchrashuvlar siyraklashadi va o'lchov o'yinni aks ettirmaydi.
  int botCount = 15,
  int seed = 11,
  double seconds = 60,
}) {
  final world = createMatch(
    config: GameConfig(botCount: botCount, difficulty: difficulty),
    playerColorIndex: 0,
    playerName: 'Siz',
    availableColors: Palette.colorCount,
    random: math.Random(seed),
  );
  // Odam o'yinchi qimirlamasin — faqat botlarni o'lchaymiz.
  world.human.speed = 0;
  const dt = 1 / 60;
  for (var i = 0; i < (seconds / dt).round(); i++) {
    world.update(dt);
  }
  return world;
}

void main() {
  group('bot AI', () {
    test('botlar yaratiladi: rang va nomlar takrorlanmaydi', () {
      final world = createMatch(
        config: const GameConfig(botCount: 9),
        playerColorIndex: 3,
        playerName: 'Siz',
        availableColors: Palette.colorCount,
        random: math.Random(5),
      );

      expect(world.players.length, 10);
      expect(world.human.isBot, isFalse);
      expect(world.players.skip(1).every((p) => p.isBot), isTrue);
      expect(world.players.skip(1).every((p) => p.brain is BotBrain), isTrue);

      final colors = world.players.map((p) => p.colorIndex).toSet();
      expect(colors.length, 10, reason: 'har kimda o\'z rangi');
      expect(
        world.players.skip(1).map((p) => p.colorIndex),
        isNot(contains(3)),
        reason: "o'yinchining rangi botlarga berilmaydi",
      );
      final names = world.players.skip(1).map((p) => p.name).toSet();
      expect(names.length, 9);
    });

    test('hamma tasodifiy, bir-biriga tegmaydigan joyda boshlaydi', () {
      final world = createMatch(
        config: const GameConfig(botCount: 9),
        playerColorIndex: 0,
        playerName: 'Siz',
        availableColors: Palette.colorCount,
        random: math.Random(9),
      );
      for (final p in world.players) {
        expect(p.alive, isTrue);
        expect(world.grid.territoryOf(p.id), 25, reason: '5x5 boshlang\'ich');
      }
    });

    test('botlar hudud egallaydi va tsikl chizadi', () {
      final world = runMatch(difficulty: Difficulty.normal, seconds: 45);
      final bots = world.players.skip(1).toList();

      final grown = bots.where((b) => world.grid.territoryOf(b.id) > 25).length;
      expect(
        grown,
        greaterThanOrEqualTo(4),
        reason: 'kamida yarmi hududini kengaytirgan bo\'lishi kerak',
      );

      final totalBotArea = bots.fold<int>(
        0,
        (sum, b) => sum + world.grid.territoryOf(b.id),
      );
      expect(
        totalBotArea,
        greaterThan(9 * 25 * 3),
        reason: 'umumiy hudud sezilarli o\'sadi',
      );
    });

    test("o'lgan bot belgilangan vaqtdan keyin qayta paydo bo'ladi", () {
      final world = createMatch(
        config: const GameConfig(botCount: 3),
        playerColorIndex: 0,
        playerName: 'Siz',
        availableColors: Palette.colorCount,
        random: math.Random(21),
      );
      final bot = world.players[1];
      expect(bot.alive, isTrue);

      world.kill(bot, DeathCause.wall, null);
      expect(bot.alive, isFalse);
      expect(world.grid.territoryOf(bot.id), 0, reason: 'hududi bo\'shaydi');

      // Kutish vaqti tugamaguncha tirilmasligi kerak.
      const dt = 1 / 60;
      final halfway = (world.config.botRespawnDelay / 2 / dt).round();
      for (var i = 0; i < halfway; i++) {
        world.update(dt);
      }
      expect(bot.alive, isFalse, reason: 'hali erta');

      for (var i = 0; i < halfway + 120; i++) {
        world.update(dt);
      }
      expect(bot.alive, isTrue, reason: 'qayta paydo bo\'ldi');
      expect(world.grid.territoryOf(bot.id), 25, reason: 'yangi 5x5 hudud');
    });

    test('botlar bir-birini ovlaydi', () {
      final world = runMatch(difficulty: Difficulty.hard, seconds: 90);
      final aliveBots = world.players.skip(1).where((p) => p.alive).length;
      expect(aliveBots, greaterThanOrEqualTo(world.config.botCount - 3));

      final kills = world.players.fold<int>(0, (s, p) => s + p.kills);
      expect(kills, greaterThan(0));
    });

    test('qiyinlik botlar tezligiga ta\'sir qiladi', () {
      for (final d in Difficulty.values) {
        final world = createMatch(
          config: GameConfig(botCount: 3, difficulty: d),
          playerColorIndex: 0,
          playerName: 'Siz',
          availableColors: Palette.colorCount,
          random: math.Random(3),
        );
        final bot = world.players[1];
        expect(
          bot.speed,
          closeTo(world.config.playerSpeed * d.botSpeedFactor, 1e-9),
        );
      }
      expect(
        Difficulty.hard.botSpeedFactor,
        greaterThan(Difficulty.easy.botSpeedFactor),
      );
      expect(
        Difficulty.hard.botLoopFactor,
        greaterThan(Difficulty.easy.botLoopFactor),
      );
    });

    test('qiyin darajada botlar ko\'proq hudud egallaydi', () {
      var easyArea = 0;
      var hardArea = 0;
      for (final seed in [1, 2, 3]) {
        final easy = runMatch(
          difficulty: Difficulty.easy,
          seed: seed,
          seconds: 40,
        );
        final hard = runMatch(
          difficulty: Difficulty.hard,
          seed: seed,
          seconds: 40,
        );
        for (final p in easy.players.skip(1)) {
          easyArea += easy.grid.territoryOf(p.id);
        }
        for (final p in hard.players.skip(1)) {
          hardArea += hard.grid.territoryOf(p.id);
        }
      }
      expect(hardArea, greaterThan(easyArea));
    });

    test('uzoq simulyatsiyada panjara buzilmaydi', () {
      final world = runMatch(difficulty: Difficulty.normal, seconds: 90);
      final grid = world.grid;

      // Hisoblagichlar haqiqiy kataklar bilan mos kelishi kerak.
      final counted = <int, int>{};
      for (var i = 0; i < grid.owner.length; i++) {
        final o = grid.owner[i];
        counted[o] = (counted[o] ?? 0) + 1;
      }
      for (final p in world.players) {
        expect(grid.territoryOf(p.id), counted[p.id] ?? 0, reason: p.name);
      }
      expect(grid.territoryOf(0), counted[0] ?? 0);

      // O'lgan o'yinchining izi qolib ketmasligi kerak.
      for (final p in world.players) {
        if (p.alive) continue;
        for (var i = 0; i < grid.trail.length; i++) {
          expect(grid.trail[i], isNot(p.id));
        }
      }

      // Hamma tirik bot xarita ichida bo'lishi kerak.
      for (final p in world.players.where((p) => p.alive)) {
        expect(grid.contains(p.cx, p.cy), isTrue, reason: p.name);
      }
    });
  });
}
