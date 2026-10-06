import 'dart:math' as math;

import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/game/logic/game_world.dart';
import 'package:color_land/game/logic/player_state.dart';

/// Testlar uchun kichik, oldindan aytib bo'ladigan dunyo.
GameWorld makeWorld({
  int width = 24,
  int height = 24,
  int seed = 7,
  double speed = 8.0,
}) {
  return GameWorld(
    config: GameConfig(
      worldMap: false,
      gridWidth: width,
      gridHeight: height,
      botCount: 0,
      playerSpeed: speed,
      playerTurnRate: 1000,
      botTurnRate: 1000,
    ),
    random: math.Random(seed),
  );
}

/// `spawn()` ning tasodifiyligiga tayanmasdan o'yinchini aniq joyga qo'yadi.
PlayerState placePlayer(
  GameWorld world, {
  required int left,
  required int top,
  int size = 5,
  String name = 'P',
  int colorIndex = 0,
  bool isBot = false,
  double angle = 0,
}) {
  final p = world.addPlayer(name: name, colorIndex: colorIndex, isBot: isBot);
  world.grid.fillBlock(left, top, size, p.id);
  p.placeAt(left + size / 2, top + size / 2, angle);
  return p;
}

/// O'yinchini `steps` katak masofaga `angle` yo'nalishda yurgizadi.
/// Qadam kichik — har katak alohida qayd etiladi.
void walk(GameWorld world, PlayerState p, double angle, double cells) {
  p.angle = angle;
  p.targetAngle = angle;
  const dt = 1 / 240;
  final total = cells / (p.speed * dt);
  for (var i = 0; i < total.ceil(); i++) {
    if (!p.alive) return;
    p.targetAngle = angle;
    world.update(dt);
  }
}

/// Panjarani matn ko'rinishida chizadi — xatoni ko'rish uchun.
String dumpOwners(GameWorld world) {
  final g = world.grid;
  final sb = StringBuffer();
  for (var y = 0; y < g.height; y++) {
    for (var x = 0; x < g.width; x++) {
      final o = g.ownerAt(x, y);
      final t = g.trailAt(x, y);
      sb.write(t != 0 ? '*' : (o == 0 ? '.' : '$o'));
    }
    sb.writeln();
  }
  return sb.toString();
}
