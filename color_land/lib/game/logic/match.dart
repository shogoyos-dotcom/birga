import 'dart:math' as math;

import 'bot_ai.dart';
import 'bot_names.dart';
import 'game_config.dart';
import 'game_world.dart';

/// Bitta o'yin (match) yaratadi: o'yinchi + botlar, hammasi joylashtirilgan.
GameWorld createMatch({
  required GameConfig config,
  required int playerColorIndex,
  required String playerName,
  required int availableColors,
  math.Random? random,
}) {
  final rng = random ?? math.Random();
  final world = GameWorld(config: config, random: rng);

  world.addPlayer(
    name: playerName,
    colorIndex: playerColorIndex % availableColors,
    isBot: false,
  );

  // Botlarga o'yinchinikidan boshqa ranglar beriladi.
  final colors = List<int>.generate(availableColors, (i) => i)
    ..remove(playerColorIndex % availableColors)
    ..shuffle(rng);
  final names = pickBotNames(config.botCount, rng);

  for (var i = 0; i < config.botCount; i++) {
    world.addPlayer(
      name: names[i],
      colorIndex: colors[i % colors.length],
      isBot: true,
      brain: BotBrain(difficulty: config.difficulty, random: rng),
    );
  }

  world.spawnAll();
  return world;
}
