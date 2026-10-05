import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/logic/game_config.dart';
import '../game/render/color_land_game.dart';
import '../game/render/palette.dart';

/// O'yin ekrani: Flame tuvali + ustidan Flutter UI.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.config, required this.colorIndex});

  final GameConfig config;
  final int colorIndex;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ColorLandGame _game;

  /// Barmoq qo'yilgan nuqta — yo'nalish shu nuqtaga nisbatan hisoblanadi.
  Offset? _dragOrigin;

  @override
  void initState() {
    super.initState();
    _game = _createGame();
  }

  ColorLandGame _createGame() {
    final game = ColorLandGame(config: widget.config);
    game.sim.addPlayer(
      name: 'Siz',
      colorIndex: widget.colorIndex,
      isBot: false,
    );
    game.sim.spawnAll();
    return game;
  }

  void _onPanStart(DragStartDetails d) {
    _dragOrigin = d.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final origin = _dragOrigin;
    if (origin == null) return;
    final delta = d.localPosition - origin;
    // Kichik tebranishlarni e'tiborsiz qoldiramiz.
    if (delta.distance < 12) return;
    _game.setSteerAngle(math.atan2(delta.dy, delta.dx));
    // Barmoq uzoqlashsa boshlang'ich nuqtani ergashtiramiz — shunda
    // yo'nalishni burish uchun ekranni to'liq kesib o'tish shart emas.
    if (delta.distance > 56) {
      _dragOrigin = d.localPosition - delta * (56 / delta.distance);
    }
  }

  void _onPanEnd() {
    _dragOrigin = null;
    _game.setSteerAngle(null);
  }

  /// Testlar uchun o'yin obyektiga kirish.
  @visibleForTesting
  ColorLandGame get gameForTest => _game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.outside,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: (_) => _onPanEnd(),
        onPanCancel: _onPanEnd,
        child: GameWidget(game: _game),
      ),
    );
  }
}
