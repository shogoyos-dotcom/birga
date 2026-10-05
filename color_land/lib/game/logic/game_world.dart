import 'dart:math' as math;
import 'dart:typed_data';

import 'game_config.dart';
import 'game_events.dart';
import 'game_grid.dart';
import 'player_state.dart';
import 'territory_capture.dart';

/// Botni boshqaradigan "miya" interfeysi. Mantiq qatlami uning ichini bilmaydi.
abstract class PlayerBrain {
  /// Har kadrda chaqiriladi; bot `self.steerTo(...)` bilan yo'nalish beradi.
  void update(GameWorld world, PlayerState self, double dt);

  /// Bot qayta tug'ilganda holatni tiklash uchun.
  void onRespawn(GameWorld world, PlayerState self) {}
}

/// O'yinning butun mantiqi: harakat, iz, hudud egallash va o'lim qoidalari.
/// Flutter yoki Flame'ga bog'liq emas — shuning uchun to'liq test qilinadi.
class GameWorld {
  GameWorld({required this.config, math.Random? random})
    : grid = GameGrid(config.gridWidth, config.gridHeight),
      rng = random ?? math.Random() {
    _capturer = TerritoryCapturer(grid);
  }

  final GameConfig config;
  final GameGrid grid;
  final math.Random rng;
  late final TerritoryCapturer _capturer;

  final List<PlayerState> players = <PlayerState>[];

  /// ID bo'yicha tezkor kirish (ID 1..255).
  final List<PlayerState?> _byId = List<PlayerState?>.filled(256, null);

  /// O'yinchi ID -> rang indeksi. Panjarada faqat ID saqlanadi, shuning uchun
  /// rang chizishda shu jadval orqali topiladi.
  final Uint8List colorIndexById = Uint8List(256);

  /// Rendering qatlami har kadrda bo'shatib oladigan hodisalar navbati.
  final List<GameEvent> events = <GameEvent>[];

  /// O'yin boshlangandan beri o'tgan vaqt (sekund).
  double elapsed = 0;

  bool get isHumanAlive => human.alive;

  PlayerState get human => players.first;

  PlayerState? playerById(int id) => (id >= 0 && id < 256) ? _byId[id] : null;

  /// Egallangan maydon bo'yicha kamayish tartibida saralangan tirik o'yinchilar.
  List<PlayerState> leaderboard() {
    final list = players.where((p) => p.alive).toList()
      ..sort(
        (a, b) => grid.territoryOf(b.id).compareTo(grid.territoryOf(a.id)),
      );
    return list;
  }

  PlayerState addPlayer({
    required String name,
    required int colorIndex,
    required bool isBot,
    PlayerBrain? brain,
  }) {
    final id = players.length + 1;
    assert(id < 256, 'Maksimal 255 o\'yinchi');
    final p = PlayerState(
      id: id,
      name: name,
      colorIndex: colorIndex,
      isBot: isBot,
      speed: isBot ? config.botSpeed : config.playerSpeed,
      turnRate: isBot ? config.botTurnRate : config.playerTurnRate,
    );
    p.brain = brain;
    players.add(p);
    _byId[id] = p;
    colorIndexById[id] = colorIndex;
    return p;
  }

  /// Hamma o'yinchini tasodifiy joyga boshlang'ich hudud bilan qo'yadi.
  void spawnAll() {
    for (final p in players) {
      spawn(p);
    }
  }

  /// Bo'sh joy topib `p` ni `startBlock x startBlock` hudud bilan joylashtiradi.
  /// Joy topilmasa `false` qaytaradi (keyinroq qayta urinish uchun).
  bool spawn(PlayerState p) {
    final size = config.startBlock;
    final margin = size + 2;
    for (var attempt = 0; attempt < 400; attempt++) {
      final left = margin + rng.nextInt(grid.width - 2 * margin - size);
      final top = margin + rng.nextInt(grid.height - 2 * margin - size);
      if (!grid.isBlockFree(left, top, size)) continue;
      final cx = left + size ~/ 2;
      final cy = top + size ~/ 2;
      grid.fillDisc(cx, cy, config.startRadius, p.id);
      p.placeAt(cx + 0.5, cy + 0.5, rng.nextDouble() * 2 * math.pi - math.pi);
      if (p.brain case final PlayerBrain b) b.onRespawn(this, p);
      events.add(RespawnEvent(p.id));
      return true;
    }
    return false;
  }

  /// Bir kadrni hisoblaydi. `dt` juda katta bo'lsa bo'laklarga bo'linadi.
  void update(double dt) {
    var remaining = dt.clamp(0.0, 0.25);
    while (remaining > 0) {
      final step = math.min(remaining, config.maxStepDt);
      _step(step);
      remaining -= step;
    }
  }

  void _step(double dt) {
    elapsed += dt;
    for (final p in players) {
      if (!p.alive) {
        if (p.isBot) {
          p.respawnTimer -= dt;
          if (p.respawnTimer <= 0 && !spawn(p)) {
            p.respawnTimer = 1.0;
          }
        }
        continue;
      }
      if (p.brain case final PlayerBrain b) b.update(this, p, dt);
      _turn(p, dt);
      _move(p, dt);
    }
  }

  void _turn(PlayerState p, double dt) {
    final diff = PlayerState.normalizeAngle(p.targetAngle - p.angle);
    final maxStep = p.turnRate * dt;
    if (diff.abs() <= maxStep) {
      p.angle = p.targetAngle;
    } else {
      p.angle = PlayerState.normalizeAngle(
        p.angle + (diff.isNegative ? -maxStep : maxStep),
      );
    }
  }

  void _move(PlayerState p, double dt) {
    final dist = p.speed * dt;
    p.x += math.cos(p.angle) * dist;
    p.y += math.sin(p.angle) * dist;

    // Tashqarida bo'lsa haqiqiy yo'lni ham yozib boramiz — iz shu bo'yicha
    // silliq chiziladi.
    if (p.trail.isNotEmpty) p.addPathPoint(p.x, p.y);

    var tx = p.x.floor();
    var ty = p.y.floor();

    // Burchakni "kesib o'tish"ni oldini olish uchun har bir katakdan
    // bittalab o'tamiz (bir kadrda odatda 0 yoki 1 qadam).
    var guard = 0;
    while (p.alive && (p.cx != tx || p.cy != ty) && guard++ < 64) {
      var sx = p.cx + (tx > p.cx ? 1 : (tx < p.cx ? -1 : 0));
      var sy = p.cy + (ty > p.cy ? 1 : (ty < p.cy ? -1 : 0));
      if (sx != p.cx && sy != p.cy) {
        // Diagonal: avval uzoqroq o'qdan yuramiz, oraliq katak o'tkazib
        // yuborilmasin.
        if ((tx - p.cx).abs() >= (ty - p.cy).abs()) {
          sy = p.cy;
        } else {
          sx = p.cx;
        }
      }
      _enterCell(p, sx, sy);
    }
  }

  void _enterCell(PlayerState p, int nx, int ny) {
    // Qoida: xarita chegarasiga urilsang — o'lasan.
    if (!grid.contains(nx, ny)) {
      kill(p, DeathCause.wall, null);
      return;
    }
    p.cx = nx;
    p.cy = ny;
    final i = grid.index(nx, ny);

    if (grid.owner[i] == p.id) {
      // O'z hududiga qaytdi — iz bo'lsa hudud egallanadi.
      if (p.trail.isNotEmpty) _finishLoop(p);
      return;
    }

    // Qoida: o'z izingni kesib o'tsang — o'lasan. Lekin endigina qo'ygan
    // bir necha katak bundan mustasno: barmoq tebranishi o'yinchini
    // ortga qaytarib yuborishi mumkin va buning uchun o'ldirish adolatsiz.
    if (grid.trail[i] == p.id) {
      if (!_isFreshTrail(p, i)) {
        kill(p, DeathCause.selfCross, null);
      }
      return;
    }

    // Qoida: kimdir sening izingga tegsa — sen o'lasan, unga +1 kill.
    final other = grid.trail[i];
    if (other != 0) {
      final victim = _byId[other];
      if (victim != null && victim.alive) kill(victim, DeathCause.trailHit, p);
    }

    if (p.trail.isEmpty) {
      // Hududdan endi chiqdi — yo'l shu nuqtadan boshlanadi.
      p.trailPath
        ..clear()
        ..add(p.x)
        ..add(p.y);
    }
    grid.setTrailIndex(i, p.id);
    p.trail.add(i);
  }

  /// `i` — `p` ning eng so'nggi `config.selfHitGrace` ta izidan birimi?
  bool _isFreshTrail(PlayerState p, int i) {
    final from = math.max(0, p.trail.length - config.selfHitGrace);
    for (var k = p.trail.length - 1; k >= from; k--) {
      if (p.trail[k] == i) return true;
    }
    return false;
  }

  void _finishLoop(PlayerState p) {
    final result = _capturer.capture(p.id, p.trail);
    p.trail.clear();
    p.trailPath.clear();
    if (result.isEmpty) return;
    events.add(CaptureEvent(p.id, result.cells));

    // Qoida: butun hududi egallangan o'yinchi o'ladi.
    for (final victimId in result.takenFrom.keys) {
      if (grid.territoryOf(victimId) != 0) continue;
      final victim = _byId[victimId];
      if (victim != null && victim.alive) {
        kill(victim, DeathCause.territoryLost, p);
      }
    }
  }

  /// O'yinchini o'ldiradi: hududi bo'sh bo'ladi, izi tozalanadi.
  void kill(PlayerState p, DeathCause cause, PlayerState? killer) {
    if (!p.alive) return;
    p.alive = false;
    p.deathCause = cause;
    p.trail.clear();
    p.trailPath.clear();
    if (killer != null && killer.id != p.id) killer.kills++;
    p.finalTerritory = grid.territoryOf(p.id);
    final cleared = grid.clearPlayer(p.id);
    p.respawnTimer = config.botRespawnDelay;
    events.add(DeathEvent(p.id, cause, killer?.id, cleared));
  }

  /// O'yinchining hozirgi (yoki o'lgan bo'lsa — o'limdagi) maydon foizi.
  double percentOf(PlayerState p) => p.alive
      ? grid.percentOf(p.id)
      : p.finalTerritory * 100.0 / grid.cellCount;

  /// O'lgan o'yinchini qaytaradi: o'limda bo'shagan kataklaridan hali
  /// bo'sh turganlari unga qaytariladi va o'yinchi o'sha hududning
  /// o'rtasiga qo'yiladi.
  ///
  /// Agar qaytariladigan katak juda kam qolgan bo'lsa (hududni boshqalar
  /// egallab bo'lgan), oddiy qoida bo'yicha yangi joyga joylashtiriladi.
  /// Hech qanday joy topilmasa `false` qaytaradi.
  bool revive(PlayerState p, List<int> cells) {
    if (p.alive) return true;

    final restored = <int>[];
    for (final i in cells) {
      if (grid.owner[i] == 0 && grid.trail[i] == 0) {
        grid.setOwnerIndex(i, p.id);
        restored.add(i);
      }
    }
    if (restored.length < config.minReviveCells) {
      // Qaytargan ozgina katakni tozalab, yangi joydan boshlaymiz.
      for (final i in restored) {
        grid.setOwnerIndex(i, 0);
      }
      return spawn(p);
    }

    var sumX = 0;
    var sumY = 0;
    for (final i in restored) {
      sumX += i % grid.width;
      sumY += i ~/ grid.width;
    }
    final cx = sumX ~/ restored.length;
    final cy = sumY ~/ restored.length;

    // Markaz boshqa o'yinchiga o'tib ketgan bo'lishi mumkin — eng yaqin
    // o'z katagimizni topamiz.
    var bestIndex = restored.first;
    var bestDist = 1 << 30;
    for (final i in restored) {
      final dx = i % grid.width - cx;
      final dy = i ~/ grid.width - cy;
      final d = dx * dx + dy * dy;
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }

    p.placeAt(
      bestIndex % grid.width + 0.5,
      bestIndex ~/ grid.width + 0.5,
      rng.nextDouble() * 2 * math.pi - math.pi,
    );
    events.add(RespawnEvent(p.id));
    return true;
  }

  /// Hodisalar navbatini bo'shatadi va nusxasini qaytaradi.
  List<GameEvent> drainEvents() {
    if (events.isEmpty) return const <GameEvent>[];
    final copy = List<GameEvent>.of(events);
    events.clear();
    return copy;
  }
}
