import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../logic/game_config.dart';
import '../logic/game_events.dart';
import '../logic/game_world.dart';
import '../logic/player_state.dart';
import 'grid_renderer.dart';
import 'hud_snapshot.dart';
import 'palette.dart';

/// Bir katakning dunyo koordinatalaridagi o'lchami.
const double kCellSize = 10.0;

/// Ekran kengligiga nechta katak sig'adi.
const double kVisibleCells = 30.0;

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

  late final GridRenderer gridRenderer;
  late final CaptureFlashLayer flashLayer;

  /// HUD uchun holat — sekundiga ~8 marta yangilanadi.
  final ValueNotifier<HudSnapshot> hud = ValueNotifier<HudSnapshot>(
    const HudSnapshot.empty(),
  );

  /// O'yinchi o'lganda chaqiriladi.
  VoidCallback? onHumanDeath;

  /// Ekranni surish yo'nalishi (radian). `null` — surilmayapti.
  double? _steerAngle;

  double _hudTimer = 0;

  /// O'yinchi qancha vaqt tirik qolgani.
  double survivedSeconds = 0;

  /// O'lgandan keyin reyting o'rni o'zgarmasin.
  int _lastRank = 1;
  int _lastAlive = 1;

  @override
  Color backgroundColor() => Palette.outside;

  @override
  Future<void> onLoad() async {
    gridRenderer = GridRenderer(sim.grid, kCellSize, sim.colorIndexById);
    flashLayer = CaptureFlashLayer();
    camera.viewfinder.anchor = Anchor.center;
    await world.addAll([
      BoardBackground(),
      GridLayer(),
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
        case RespawnEvent():
          break;
      }
    }

    gridRenderer.invalidateDirty();
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
      onHumanDeath?.call();
    }
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
            colorIndex: p.colorIndex,
            percent: sim.grid.percentOf(p.id),
            isHuman: !p.isBot,
          ),
      ],
    );
  }

  @override
  void onRemove() {
    gridRenderer.dispose();
    hud.dispose();
    super.onRemove();
  }
}

/// Fon: ochiq rang, mayin panjara chiziqlari va xarita chegarasi.
class BoardBackground extends Component with HasGameReference<ColorLandGame> {
  BoardBackground() : super(priority: 0);

  final Paint _bg = Paint()..color = Palette.background;
  final Paint _border = Paint()
    ..color = Palette.mapBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = kCellSize * 0.9;

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

    // Panjara chiziqlari ataylab chizilmaydi: maydon tekis ko'rinadi,
    // hudud va izlar esa o'z ranglari bilan ajralib turadi.
    canvas.drawRect(area, _bg);
    canvas.drawRect(mapRect.deflate(_border.strokeWidth / 2), _border);
  }
}

/// Egallangan hudud va izlar — keshlangan chunklar orqali.
class GridLayer extends Component with HasGameReference<ColorLandGame> {
  GridLayer() : super(priority: 10);

  @override
  void render(ui.Canvas canvas) {
    game.gridRenderer.render(canvas, game.camera.visibleWorldRect);
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

  /// Juda katta egallashda har bir katakni chizmaymiz — chegara qo'yamiz.
  static const int _maxRects = 1600;

  final List<_Flash> _flashes = <_Flash>[];
  final Paint _paint = Paint()..isAntiAlias = false;

  int get activeCount => _flashes.length;

  void addFlash(GameWorld sim, int playerId, List<int> cells, FlashKind kind) {
    final rects = _mergeRuns(sim, cells);
    if (rects.isEmpty) return;
    _flashes.add(_Flash(rects, Palette.head(_colorOf(sim, playerId)), kind));
  }

  int _colorOf(GameWorld sim, int playerId) =>
      sim.playerById(playerId)?.colorIndex ?? 0;

  /// Qatorlardagi ketma-ket kataklarni bitta to'rtburchakka birlashtiradi.
  List<Rect> _mergeRuns(GameWorld sim, List<int> cells) {
    if (cells.isEmpty) return const <Rect>[];
    final w = sim.grid.width;
    final sorted = List<int>.of(cells)..sort();
    final rects = <Rect>[];
    var runStart = sorted.first;
    var prev = sorted.first;
    for (var k = 1; k <= sorted.length; k++) {
      final cur = k < sorted.length ? sorted[k] : -1;
      final continues = cur == prev + 1 && cur % w != 0;
      if (!continues) {
        final x = runStart % w;
        final y = runStart ~/ w;
        rects.add(
          Rect.fromLTWH(
            x * kCellSize,
            y * kCellSize,
            (prev - runStart + 1) * kCellSize,
            kCellSize,
          ),
        );
        if (rects.length >= _maxRects) {
          // Juda ko'p — bitta umumiy to'rtburchak bilan cheklanamiz.
          return <Rect>[rects.reduce((a, b) => a.expandToInclude(b))];
        }
        runStart = cur;
      }
      prev = cur;
    }
    return rects;
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
      _paint.color = color.withValues(alpha: alpha);
      for (final rect in flash.rects) {
        if (!rect.overlaps(visible)) continue;
        canvas.drawRect(rect, _paint);
      }
    }
  }
}

class _Flash {
  _Flash(this.rects, this.color, this.kind);

  final List<Rect> rects;
  final Color color;
  final FlashKind kind;
  double age = 0;
}

/// O'yinchilar kvadratlari va nomlari.
class PlayersLayer extends Component with HasGameReference<ColorLandGame> {
  PlayersLayer() : super(priority: 30);

  late final HeadPainter _painter = HeadPainter(kCellSize);

  @override
  void render(ui.Canvas canvas) {
    final visible = game.camera.visibleWorldRect.inflate(kCellSize * 3);
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
