import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../logic/game_config.dart';
import '../logic/game_world.dart';
import '../logic/player_state.dart';
import 'grid_renderer.dart';
import 'palette.dart';

/// Bir katakning dunyo koordinatalaridagi o'lchami.
const double kCellSize = 10.0;

/// Ekran kengligiga nechta katak sig'adi.
const double kVisibleCells = 34.0;

/// Flame o'yini — faqat rendering va kiritish bilan shug'ullanadi,
/// butun mantiq [GameWorld] (`sim`) ichida.
class ColorLandGame extends FlameGame {
  ColorLandGame({required this.config, math.Random? random})
    : sim = GameWorld(config: config, random: random);

  final GameConfig config;

  /// O'yin mantiqi (Flame'ning `world` komponenti bilan aralashmasligi uchun
  /// `sim` deb nomlangan).
  final GameWorld sim;

  late final GridRenderer gridRenderer;

  /// Ekranni surish yo'nalishi (radian). `null` — surilmayapti.
  double? _steerAngle;

  /// O'yinchi qancha vaqt tirik qolgani — natija oynasi uchun.
  double? survivedSeconds;

  @override
  Color backgroundColor() => Palette.outside;

  @override
  Future<void> onLoad() async {
    gridRenderer = GridRenderer(sim.grid, kCellSize);
    camera.viewfinder.anchor = Anchor.center;
    await world.addAll([BoardBackground(), GridLayer(), PlayersLayer()]);
    _applyZoom(size);
    _centerOnHuman();
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

  void _centerOnHuman() {
    final p = sim.human;
    camera.viewfinder.position = Vector2(p.x * kCellSize, p.y * kCellSize);
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
    if (wasAlive && !human.alive) {
      survivedSeconds = sim.elapsed;
    }

    gridRenderer.invalidateDirty();
    if (human.alive) _centerOnHuman();
  }

  @override
  void onRemove() {
    gridRenderer.dispose();
    super.onRemove();
  }
}

/// Fon: ochiq rang, mayin panjara chiziqlari va xarita chegarasi.
class BoardBackground extends Component with HasGameReference<ColorLandGame> {
  BoardBackground() : super(priority: 0);

  final Paint _bg = Paint()..color = Palette.background;
  final Paint _line = Paint()
    ..color = Palette.gridLine
    ..strokeWidth = 1.0
    ..isAntiAlias = false;
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

    canvas.drawRect(area, _bg);

    // Panjara chiziqlari — faqat ko'rinadigan oraliqda.
    final x0 = (area.left / kCellSize).floor();
    final x1 = (area.right / kCellSize).ceil();
    final y0 = (area.top / kCellSize).floor();
    final y1 = (area.bottom / kCellSize).ceil();
    for (var x = x0; x <= x1; x++) {
      final wx = x * kCellSize;
      canvas.drawLine(Offset(wx, area.top), Offset(wx, area.bottom), _line);
    }
    for (var y = y0; y <= y1; y++) {
      final wy = y * kCellSize;
      canvas.drawLine(Offset(area.left, wy), Offset(area.right, wy), _line);
    }

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

/// O'yinchilar kvadratlari.
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
}
