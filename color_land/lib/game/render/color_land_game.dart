import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../logic/game_config.dart';
import '../logic/game_events.dart';
import '../logic/game_world.dart';
import '../logic/player_state.dart';
import 'avatar_painter.dart';
import 'contour.dart';
import 'head_painter.dart';
import 'shape_painter.dart';
import 'hud_snapshot.dart';
import 'palette.dart';

/// Bir katakning dunyo koordinatalaridagi o'lchami.
const double kCellSize = 10.0;

/// Ekran kengligiga nechta katak sig'adi.
const double kVisibleCells = 48.0;

/// HUD sekundiga necha marta yangilanadi.
const double _kHudInterval = 0.12;

/// Flame o'yini — faqat rendering va kiritish bilan shug'ullanadi,
/// butun mantiq [GameWorld] (`sim`) ichida.
class ColorLandGame extends FlameGame {
  ColorLandGame({required this.sim});

  /// O'yin mantiqi (Flame'ning `world` komponenti bilan aralashmasligi uchun
  /// `sim` deb nomlangan).
  final GameWorld sim;

  GameConfig get config => sim.config;

  late final TerritoryShapes territoryShapes;
  late final CaptureFlashLayer flashLayer;

  /// HUD uchun holat — sekundiga ~8 marta yangilanadi.
  final ValueNotifier<HudSnapshot> hud = ValueNotifier<HudSnapshot>(
    const HudSnapshot.empty(),
  );

  /// O'yinchi o'lganda chaqiriladi; argument — bo'shagan kataklar
  /// (davom etilsa shular qaytariladi).
  void Function(List<int> clearedCells)? onHumanDeath;

  /// Ekranni surish yo'nalishi (radian). `null` — surilmayapti.
  double? _steerAngle;

  double _hudTimer = 0;

  /// O'yinchi qancha vaqt tirik qolgani.
  double survivedSeconds = 0;

  /// O'yinchi o'limida bo'shagan kataklar.
  List<int> _humanCleared = const <int>[];

  /// O'lgandan keyin reyting o'rni o'zgarmasin.
  int _lastRank = 1;
  int _lastAlive = 1;

  @override
  Color backgroundColor() => Palette.outside;

  @override
  Future<void> onLoad() async {
    territoryShapes = TerritoryShapes(sim.grid, kCellSize);
    flashLayer = CaptureFlashLayer();
    camera.viewfinder.anchor = Anchor.center;
    await world.addAll([
      BoardBackground(),
      TerritoryLayer(),
      AvatarLayer(),
      flashLayer,
      PlayersLayer(),
    ]);
    _applyZoom(size);
    _centerOnHuman();
    _refreshHud();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyZoom(size);
  }

  void _applyZoom(Vector2 size) {
    if (size.x <= 0) return;
    camera.viewfinder.zoom = size.x / (kVisibleCells * kCellSize);
  }

  /// Kamerani o'yinchiga qaratadi, lekin xarita tashqarisi ko'rinib
  /// ketmasligi uchun chegaraga tiraydi.
  void _centerOnHuman() {
    final p = sim.human;
    final zoom = camera.viewfinder.zoom;
    final halfW = size.x / zoom / 2;
    final halfH = size.y / zoom / 2;
    final mapW = sim.grid.width * kCellSize;
    final mapH = sim.grid.height * kCellSize;

    // Yengil chekka — chegara chizig'i to'liq ko'rinsin.
    const pad = kCellSize * 1.5;
    double clamp(double value, double half, double extent) {
      if (half * 2 >= extent + pad * 2) return extent / 2;
      return value.clamp(half - pad, extent - half + pad);
    }

    camera.viewfinder.position = Vector2(
      clamp(p.x * kCellSize, halfW, mapW),
      clamp(p.y * kCellSize, halfH, mapH),
    );
  }

  /// Ekranni surish yo'nalishi (radian) yoki `null`.
  void setSteerAngle(double? angle) => _steerAngle = angle;

  @override
  void update(double dt) {
    super.update(dt);

    final human = sim.human;
    if (human.alive && _steerAngle != null) {
      human.steerTo(_steerAngle!);
    }

    final wasAlive = human.alive;
    sim.update(dt);

    for (final event in sim.drainEvents()) {
      switch (event) {
        case CaptureEvent(:final playerId, :final cells):
          flashLayer.addFlash(sim, playerId, cells, FlashKind.capture);
        case DeathEvent(:final playerId, :final clearedCells):
          flashLayer.addFlash(sim, playerId, clearedCells, FlashKind.death);
          if (playerId == sim.human.id) _humanCleared = clearedCells;
        case RespawnEvent():
          break;
      }
    }

    flashLayer.advance(dt);

    if (human.alive) {
      survivedSeconds = sim.elapsed;
      _centerOnHuman();
    }

    _hudTimer -= dt;
    if (_hudTimer <= 0) {
      _hudTimer = _kHudInterval;
      _refreshHud();
    }

    if (wasAlive && !human.alive) {
      _refreshHud();
      onHumanDeath?.call(_humanCleared);
    }
  }

  /// Davom etilgandan keyin o'yinni qaytadan yurgizadi.
  void resumeAfterRevive() {
    paused = false;
    _humanCleared = const <int>[];
    _refreshHud();
  }

  void _refreshHud() {
    final board = sim.leaderboard();
    final human = sim.human;
    if (human.alive) {
      final index = board.indexWhere((p) => p.id == human.id);
      _lastRank = (index < 0 ? board.length : index) + 1;
      _lastAlive = board.length;
    }
    hud.value = HudSnapshot(
      percent: sim.percentOf(human),
      kills: human.kills,
      elapsed: survivedSeconds,
      rank: _lastRank,
      alivePlayers: _lastAlive,
      top: [
        for (final p in board.take(5))
          ScoreRow(
            id: p.id,
            name: p.name,
            avatar: p.avatar,
            colorIndex: p.colorIndex,
            percent: sim.grid.percentOf(p.id),
            isHuman: !p.isBot,
          ),
      ],
    );
  }

  @override
  void onRemove() {
    territoryShapes.dispose();
    hud.dispose();
    super.onRemove();
  }
}

/// Arena foni: tekis yuza, aniq panjara va neon chegara.
///
/// Panjara chiziqlari bitta `drawRawPoints` chaqiruvida chiziladi —
/// ekranda ~130 ta chiziq bo'lsa ham bitta chizish amali bo'ladi.
class BoardBackground extends Component with HasGameReference<ColorLandGame> {
  BoardBackground() : super(priority: 0);

  /// Har nechanchi katakda yo'g'onroq chiziq chiziladi.
  static const int majorEvery = 5;

  final Paint _bg = Paint();
  final Paint _minor = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final Paint _major = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  final Paint _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kCellSize * 0.5;
  final Paint _borderGlow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kCellSize * 1.6;

  Float32List _minorPoints = Float32List(0);
  Float32List _majorPoints = Float32List(0);

  @override
  void render(ui.Canvas canvas) {
    final grid = game.sim.grid;
    final mapRect = Rect.fromLTWH(
      0,
      0,
      grid.width * kCellSize,
      grid.height * kCellSize,
    );
    final visible = game.camera.visibleWorldRect;
    final area = visible.intersect(mapRect);
    if (area.isEmpty) return;

    _bg.color = Palette.background;
    canvas.drawRect(area, _bg);

    final (minor, major) = buildGridPoints(area, mapRect);
    _minorPoints = minor;
    _majorPoints = major;
    _minor.color = Palette.gridLine;
    _major.color = Palette.gridMajor;
    if (_minorPoints.isNotEmpty) {
      canvas.drawRawPoints(ui.PointMode.lines, _minorPoints, _minor);
    }
    if (_majorPoints.isNotEmpty) {
      canvas.drawRawPoints(ui.PointMode.lines, _majorPoints, _major);
    }

    // Chegara: ichkarida yo'g'on, shaffof yorug'lik + ustidan aniq chiziq.
    final border = mapRect.deflate(_border.strokeWidth / 2);
    _borderGlow.color = Palette.mapBorder.withValues(alpha: 0.18);
    canvas.drawRect(mapRect.deflate(_borderGlow.strokeWidth / 2), _borderGlow);
    _border.color = Palette.mapBorder;
    canvas.drawRect(border, _border);
  }

  /// Ko'rinadigan qism uchun chiziq uchlarini tayyorlaydi.
  /// Testlar ham shuni chaqiradi.
  static (Float32List, Float32List) buildGridPoints(Rect area, Rect map) {
    final minor = <double>[];
    final major = <double>[];

    final firstX = (area.left / kCellSize).floor();
    final lastX = (area.right / kCellSize).ceil();
    for (var i = firstX; i <= lastX; i++) {
      final x = i * kCellSize;
      if (x < map.left || x > map.right) continue;
      final list = i % majorEvery == 0 ? major : minor;
      list.addAll(<double>[x, area.top, x, area.bottom]);
    }

    final firstY = (area.top / kCellSize).floor();
    final lastY = (area.bottom / kCellSize).ceil();
    for (var i = firstY; i <= lastY; i++) {
      final y = i * kCellSize;
      if (y < map.top || y > map.bottom) continue;
      final list = i % majorEvery == 0 ? major : minor;
      list.addAll(<double>[area.left, y, area.right, y]);
    }

    return (Float32List.fromList(minor), Float32List.fromList(major));
  }
}

/// Egallangan hududlar — har o'yinchi uchun yumaloq, silliq shakl.
class TerritoryLayer extends Component with HasGameReference<ColorLandGame> {
  TerritoryLayer() : super(priority: 10);

  @override
  void render(ui.Canvas canvas) {
    game.territoryShapes.render(
      canvas,
      game.sim.players.where((p) => p.alive || p.finalTerritory > 0),
      game.camera.visibleWorldRect,
    );
  }
}

/// Hudud ustida o'yinchi avatarini chizadi.
///
/// Joy (markaz va o'lcham) [TerritoryShapes] keshida hudud bilan birga
/// hisoblangan — bu yerda faqat chizish qoladi.
class AvatarLayer extends Component with HasGameReference<ColorLandGame> {
  AvatarLayer() : super(priority: 15);

  final AvatarPainter _painter = AvatarPainter();

  @override
  void render(ui.Canvas canvas) {
    final visible = game.camera.visibleWorldRect;
    for (final PlayerState p in game.sim.players) {
      if (!p.alive) continue;
      final slot = game.territoryShapes.slotOf(p.id);
      if (slot == null) continue;
      if (!visible.inflate(slot.size).contains(slot.center)) continue;
      _painter.paint(canvas, p.avatar, slot.center, slot.size);
    }
  }

  @override
  void onRemove() {
    _painter.dispose();
    super.onRemove();
  }
}

/// Animatsiya turi.
enum FlashKind {
  /// Hudud egallandi — oqdan o'yinchi rangiga o'tadigan yorug'lik.
  capture,

  /// O'yinchi o'ldi — hududi o'z rangida so'nadi.
  death,
}

/// Hudud egallanganda va o'yinchi o'lganda qisqa animatsiya.
class CaptureFlashLayer extends Component with HasGameReference<ColorLandGame> {
  CaptureFlashLayer() : super(priority: 20);

  static const double _captureDuration = 0.45;
  static const double _deathDuration = 0.7;

  final List<_Flash> _flashes = <_Flash>[];
  final Paint _paint = Paint()..isAntiAlias = true;

  int get activeCount => _flashes.length;

  void addFlash(GameWorld sim, int playerId, List<int> cells, FlashKind kind) {
    if (cells.isEmpty) return;
    final path = _buildPath(sim, cells);
    if (path == null) return;
    _flashes.add(_Flash(path, Palette.head(_colorOf(sim, playerId)), kind));
  }

  int _colorOf(GameWorld sim, int playerId) =>
      sim.playerById(playerId)?.colorIndex ?? 0;

  /// Kataklar to'plamidan hudud bilan bir xil uslubdagi silliq shakl.
  Path? _buildPath(GameWorld sim, List<int> cells) {
    final w = sim.grid.width;
    final set = cells.toSet();
    var minX = w;
    var minY = sim.grid.height;
    var maxX = -1;
    var maxY = -1;
    for (final i in cells) {
      final x = i % w;
      final y = i ~/ w;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    if (maxX < 0) return null;

    final loops = ContourBuilder.trace(
      (x, y) => set.contains(y * w + x),
      minX,
      minY,
      maxX,
      maxY,
    );
    final path = Path()..fillType = PathFillType.nonZero;
    for (final raw in loops) {
      final pts = ContourBuilder.smooth(
        ContourBuilder.simplify(
          ContourBuilder.dropCollinear(raw),
          TerritoryShapes.simplifyTolerance,
        ),
        iterations: TerritoryShapes.smoothPasses,
      );
      if (pts.length < 3) continue;
      path.moveTo(pts[0].dx * kCellSize, pts[0].dy * kCellSize);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx * kCellSize, pts[i].dy * kCellSize);
      }
      path.close();
    }
    return path;
  }

  static double durationOf(FlashKind kind) => switch (kind) {
    FlashKind.capture => _captureDuration,
    FlashKind.death => _deathDuration,
  };

  void advance(double dt) {
    for (var i = _flashes.length - 1; i >= 0; i--) {
      final flash = _flashes[i];
      flash.age += dt;
      if (flash.age >= durationOf(flash.kind)) _flashes.removeAt(i);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_flashes.isEmpty) return;
    final visible = game.camera.visibleWorldRect;
    for (final flash in _flashes) {
      final t = (flash.age / durationOf(flash.kind)).clamp(0.0, 1.0);
      final Color color;
      final double alpha;
      if (flash.kind == FlashKind.capture) {
        // Tez porlab, sekin so'nadi: oqdan o'yinchi rangiga.
        alpha = (1 - t) * (1 - t) * 0.75;
        color = Color.lerp(const Color(0xFFFFFFFF), flash.color, t)!;
      } else {
        // O'lim: hudud o'z rangida qolib, asta so'nadi.
        alpha = (1 - t) * 0.85;
        color = flash.color;
      }
      if (alpha <= 0.01) continue;
      if (!flash.path.getBounds().overlaps(visible)) continue;
      _paint.color = color.withValues(alpha: alpha);
      canvas.drawPath(flash.path, _paint);
    }
  }
}

class _Flash {
  _Flash(this.path, this.color, this.kind);

  final Path path;
  final Color color;
  final FlashKind kind;
  double age = 0;
}

/// O'yinchilar kvadratlari va nomlari.
class PlayersLayer extends Component with HasGameReference<ColorLandGame> {
  PlayersLayer() : super(priority: 30);

  late final HeadPainter _painter = HeadPainter(kCellSize);
  late final TrailPainter _trails = TrailPainter(kCellSize);

  @override
  void render(ui.Canvas canvas) {
    final visible = game.camera.visibleWorldRect.inflate(kCellSize * 3);

    // Avval izlar — boshlar ularning ustida turadi.
    for (final PlayerState p in game.sim.players) {
      if (!p.alive || p.trailPath.length < 2) continue;
      _trails.paint(canvas, p);
    }
    for (final PlayerState p in game.sim.players) {
      if (!p.alive) continue;
      if (!visible.contains(Offset(p.x * kCellSize, p.y * kCellSize))) continue;
      _painter.paint(canvas, p);
    }
  }

  @override
  void onRemove() {
    _painter.dispose();
    super.onRemove();
  }
}
