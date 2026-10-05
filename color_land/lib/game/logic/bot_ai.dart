import 'dart:math' as math;

import 'difficulty.dart';
import 'game_world.dart';
import 'player_state.dart';

/// Botning hozirgi niyati.
enum BotPhase {
  /// O'z hududida — chiqish yo'nalishini tanlayapti.
  planning,

  /// Tashqarida tsikl chizmoqda.
  looping,

  /// Uyiga qaytmoqda.
  returning,

  /// Raqibning himoyasiz iziga hujum qilmoqda.
  hunting,
}

/// Oddiy, lekin tirik ko'rinadigan bot.
///
/// Xulq-atvori:
///  * o'z hududidan chiqib to'rtburchak tsikl chizadi va qaytadi;
///  * raqib yaqinlashsa darhol uyiga qaytadi;
///  * yaqinda himoyasiz iz ko'rsa — unga hujum qiladi;
///  * oldidagi katakda o'z izi yoki devor bo'lsa — chetlab o'tadi.
///
/// Yo'nalishlar faqat to'rt tomonga — shunda tsikllar toza to'rtburchak
/// bo'ladi va bot o'z izini tasodifan kesib o'tmaydi.
class BotBrain implements PlayerBrain {
  BotBrain({required this.difficulty, required math.Random random})
    : _rng = random;

  final Difficulty difficulty;
  final math.Random _rng;

  BotPhase phase = BotPhase.planning;

  /// Oxirgi marta o'z hududida turgan katak — qaytish nuqtasi.
  int homeX = 0;
  int homeY = 0;

  /// Rejalashtirilgan tsikl bosqichlari: (yo'nalish, uzunlik kataklarda).
  final List<_Leg> _legs = <_Leg>[];
  int _legIndex = 0;
  double _legLeft = 0;

  double _thinkTimer = 0;

  /// Hujum qilinayotgan nishon kataklari.
  int _targetX = 0;
  int _targetY = 0;

  @override
  void onRespawn(GameWorld world, PlayerState self) {
    phase = BotPhase.planning;
    _legs.clear();
    _legIndex = 0;
    _legLeft = 0;
    _thinkTimer = 0;
    homeX = self.cx;
    homeY = self.cy;
  }

  @override
  void update(GameWorld world, PlayerState self, double dt) {
    final grid = world.grid;
    final atHome =
        grid.contains(self.cx, self.cy) &&
        grid.ownerAt(self.cx, self.cy) == self.id;
    if (atHome) {
      homeX = self.cx;
      homeY = self.cy;
      if (phase != BotPhase.hunting) {
        // Uyga yetib keldi — yangi reja.
        if (phase == BotPhase.returning || _legs.isEmpty) {
          phase = BotPhase.planning;
        }
      }
    }

    _legLeft -= self.speed * dt;
    _thinkTimer -= dt;
    if (_thinkTimer > 0) {
      _avoidImmediateDanger(world, self);
      return;
    }
    _thinkTimer = difficulty.reactionDelay;

    switch (phase) {
      case BotPhase.planning:
        _plan(world, self);
      case BotPhase.looping:
        if (_isThreatened(world, self)) {
          phase = BotPhase.returning;
        } else if (_legLeft <= 0) {
          _legIndex++;
          if (_legIndex >= _legs.length) {
            phase = BotPhase.returning;
          } else {
            _legLeft = _legs[_legIndex].cells;
            self.steerTo(_legs[_legIndex].angle);
          }
        }
      case BotPhase.hunting:
        final target = _findPrey(world, self);
        if (target == null || _isThreatened(world, self)) {
          phase = BotPhase.returning;
        } else {
          _targetX = target.$1;
          _targetY = target.$2;
          self.steerTo(_cardinalToward(self, _targetX + 0.5, _targetY + 0.5));
        }
      case BotPhase.returning:
        if (atHome) {
          phase = BotPhase.planning;
        } else {
          self.steerTo(_cardinalToward(self, homeX + 0.5, homeY + 0.5));
        }
    }

    _avoidImmediateDanger(world, self);
  }

  /// O'z hududidan chiqib to'rtburchak chizadigan reja tuzadi.
  void _plan(GameWorld world, PlayerState self) {
    _legs.clear();
    _legIndex = 0;

    // Avval hujum qilish arziydimi?
    final prey = _findPrey(world, self);
    if (prey != null) {
      phase = BotPhase.hunting;
      _targetX = prey.$1;
      _targetY = prey.$2;
      self.steerTo(_cardinalToward(self, _targetX + 0.5, _targetY + 0.5));
      return;
    }

    final base = (4 + _rng.nextInt(5)) * difficulty.botLoopFactor;
    final out = _outwardAngle(world, self);
    final side = _rng.nextBool() ? 1 : -1;

    _legs
      ..add(_Leg(out, base + 2))
      ..add(_Leg(_rotate(out, side), math.max(2.0, base * 0.8)))
      ..add(_Leg(_rotate(out, side * 2), base + 4));

    phase = BotPhase.looping;
    _legLeft = _legs.first.cells;
    self.steerTo(_legs.first.angle);
  }

  /// Hududning markazidan tashqariga qaragan to'rt tomondan birini tanlaydi.
  double _outwardAngle(GameWorld world, PlayerState self) {
    final grid = world.grid;
    // Qaysi tomonda bo'sh joy ko'proq — o'shanga chiqadi.
    const dirs = <double>[0, math.pi / 2, math.pi, -math.pi / 2];
    var best = dirs[_rng.nextInt(4)];
    var bestScore = -1.0;
    for (final d in dirs) {
      var score = 0.0;
      for (var step = 1; step <= 8; step++) {
        final x = (self.x + math.cos(d) * step).floor();
        final y = (self.y + math.sin(d) * step).floor();
        if (!grid.contains(x, y)) {
          score -= 6;
          break;
        }
        final owner = grid.ownerAt(x, y);
        if (owner == 0) score += 1;
        if (owner != 0 && owner != self.id) score += 0.5;
        if (grid.trailAt(x, y) != 0) score -= 2;
      }
      score += _rng.nextDouble();
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return best;
  }

  /// Yaqin atrofda himoyasiz iz bormi? Bo'lsa — eng yaqin katagini qaytaradi.
  (int, int)? _findPrey(GameWorld world, PlayerState self) {
    final grid = world.grid;
    final r2 = difficulty.huntRadius * difficulty.huntRadius;
    (int, int)? best;
    var bestDist = double.infinity;

    for (final other in world.players) {
      if (other.id == self.id || !other.alive || other.trail.isEmpty) continue;
      for (final cell in other.trail) {
        final x = cell % grid.width;
        final y = cell ~/ grid.width;
        final dx = x + 0.5 - self.x;
        final dy = y + 0.5 - self.y;
        final d2 = dx * dx + dy * dy;
        if (d2 > r2 || d2 >= bestDist) continue;
        // Raqib o'sha katakka mendan tezroq yetib borsa — ma'nosi yo'q.
        final ox = other.x - (x + 0.5);
        final oy = other.y - (y + 0.5);
        if (ox * ox + oy * oy < d2 * 0.6) continue;
        bestDist = d2;
        best = (x, y);
      }
    }
    return best;
  }

  /// Tashqarida turganda yaqin atrofda raqib bormi?
  bool _isThreatened(GameWorld world, PlayerState self) {
    if (self.trail.isEmpty) return false;
    final r = difficulty.dangerRadius;
    final r2 = r * r;
    for (final other in world.players) {
      if (other.id == self.id || !other.alive) continue;
      final dx = other.x - self.x;
      final dy = other.y - self.y;
      if (dx * dx + dy * dy < r2) return true;
    }
    // Iz juda uzayib ketdi — xavfli, qaytgan ma'qul.
    return self.trail.length > 70 * difficulty.botLoopFactor;
  }

  /// Oldinda devor yoki o'z izi bo'lsa yo'nalishni o'zgartiradi.
  void _avoidImmediateDanger(GameWorld world, PlayerState self) {
    final blocked = _isBlocked(world, self, self.targetAngle);
    if (!blocked) return;

    // Uyga yaqinroq bo'lgan ochiq tomonni tanlaymiz.
    const dirs = <double>[0, math.pi / 2, math.pi, -math.pi / 2];
    double? best;
    var bestScore = double.negativeInfinity;
    for (final d in dirs) {
      if (_isBlocked(world, self, d)) continue;
      // Orqaga qaytish — o'z iziga kirish degani, undan qochamiz.
      final back = (PlayerState.normalizeAngle(d - self.angle)).abs();
      if (back > math.pi * 0.9) continue;
      final nx = self.x + math.cos(d) * 3;
      final ny = self.y + math.sin(d) * 3;
      final dist = math.sqrt(
        math.pow(nx - (homeX + 0.5), 2) + math.pow(ny - (homeY + 0.5), 2),
      );
      final score = -dist;
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    if (best != null) {
      self.steerTo(best);
      phase = BotPhase.returning;
    }
  }

  /// `angle` yo'nalishida yaqin kataklarda devor yoki o'z izi bormi?
  bool _isBlocked(GameWorld world, PlayerState self, double angle) {
    final grid = world.grid;
    final steps = self.trail.isEmpty ? 2 : 3;
    for (var step = 1; step <= steps; step++) {
      final x = (self.x + math.cos(angle) * step).floor();
      final y = (self.y + math.sin(angle) * step).floor();
      if (!grid.contains(x, y)) return true;
      if (grid.trailAt(x, y) == self.id) return true;
    }
    return false;
  }

  /// Nishonga qarab eng mos to'rt tomondan birini tanlaydi.
  double _cardinalToward(PlayerState self, double tx, double ty) {
    final dx = tx - self.x;
    final dy = ty - self.y;
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? 0.0 : math.pi;
    }
    return dy >= 0 ? math.pi / 2 : -math.pi / 2;
  }

  /// Burchakni 90° * `quarters` ga buradi.
  double _rotate(double angle, int quarters) =>
      PlayerState.normalizeAngle(angle + quarters * math.pi / 2);
}

class _Leg {
  const _Leg(this.angle, this.cells);

  final double angle;
  final double cells;
}
