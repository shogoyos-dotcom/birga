import 'dart:math' as math;

import 'game_events.dart';

/// Bitta o'yinchining (odam yoki bot) holati. Rendering'dan mustaqil.
class PlayerState {
  PlayerState({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.isBot,
    required this.speed,
    required this.turnRate,
  });

  /// 1..255. 0 — "bo'sh katak" ma'nosini bildiradi, shuning uchun ishlatilmaydi.
  final int id;
  final String name;
  final int colorIndex;
  final bool isBot;

  double speed;
  double turnRate;

  /// Uzluksiz pozitsiya, katak birligida (masalan 12.5 — 12-katak o'rtasi).
  double x = 0;
  double y = 0;

  /// Hozirgi katak koordinatalari.
  int cx = 0;
  int cy = 0;

  /// Harakat yo'nalishi (radian) va intilayotgan yo'nalish.
  double angle = 0;
  double targetAngle = 0;

  bool alive = false;
  int kills = 0;
  double respawnTimer = 0;

  /// O'lim paytidagi hudud hajmi (katak). O'lganda panjara tozalanadi,
  /// shuning uchun natija oynasi uchun shu yerda saqlanadi.
  int finalTerritory = 0;

  /// O'z hududidan tashqarida chizilgan iz kataklari (tartib bilan).
  final List<int> trail = <int>[];

  DeathCause deathCause = DeathCause.none;

  /// Bot miyasining ichki holati (faqat botlar uchun).
  Object? brain;

  bool get isOutside => trail.isNotEmpty;

  void placeAt(double px, double py, double dir) {
    x = px;
    y = py;
    cx = px.floor();
    cy = py.floor();
    angle = dir;
    targetAngle = dir;
    trail.clear();
    alive = true;
    deathCause = DeathCause.none;
    respawnTimer = 0;
    finalTerritory = 0;
  }

  void steerTo(double dir) => targetAngle = normalizeAngle(dir);

  /// Burchakni [-pi, pi] oralig'iga keltiradi.
  static double normalizeAngle(double a) {
    var r = a % (2 * math.pi);
    if (r > math.pi) r -= 2 * math.pi;
    if (r < -math.pi) r += 2 * math.pi;
    return r;
  }
}
