import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/logic/game_config.dart';
import '../game/logic/match.dart';
import '../game/render/color_land_game.dart';
import '../game/render/hud_snapshot.dart';
import '../game/render/palette.dart';
import '../i18n/l10n.dart';
import '../storage/settings_store.dart';
import 'widgets/game_hud.dart';
import 'widgets/result_sheet.dart';
import 'widgets/ui_kit.dart';

/// O'yin ekrani: Flame tuvali + ustidan Flutter UI.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.config,
    required this.colorIndex,
    required this.store,
  });

  final GameConfig config;
  final int colorIndex;
  final SettingsStore store;

  @override
  State<GameScreen> createState() => GameScreenState();
}

/// Testlar uchun ochiq — `gameForTest` orqali o'yinga kirish mumkin.
class GameScreenState extends State<GameScreen> {
  late ColorLandGame _game;

  /// Barmoq qo'yilgan nuqta — yo'nalish shu nuqtaga nisbatan hisoblanadi.
  Offset? _dragOrigin;

  bool _showResult = false;
  bool _isRecord = false;
  bool _showPause = false;
  bool _showHint = true;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nom `L10n` dan olinadi, u esa initState'da hali mavjud emas.
    if (_started) return;
    _started = true;
    _cachedName = L10n.of(context).you;
    _game = _createGame();
  }

  ColorLandGame _createGame() {
    final sim = createMatch(
      config: widget.config,
      playerColorIndex: widget.colorIndex,
      playerName: _playerName,
      availableColors: Palette.colorCount,
    );
    final game = ColorLandGame(sim: sim)..onHumanDeath = _onDeath;
    return game;
  }

  /// Interfeys tili o'zgarsa ham o'yin ichidagi nom o'zgarmasin —
  /// o'yin boshlanganda bir marta olinadi.
  String get _playerName => _cachedName ?? 'You';
  String? _cachedName;

  Future<void> _onDeath() async {
    final hud = _game.hud.value;
    final isRecord = await widget.store.submitResult(
      percent: hud.percent,
      kills: hud.kills,
    );
    if (!mounted) return;
    setState(() {
      _showResult = true;
      _isRecord = isRecord;
      _game.paused = true;
    });
  }

  void _restart() {
    setState(() {
      _showResult = false;
      _showPause = false;
      _showHint = true;
      _game = _createGame();
    });
  }

  void _togglePause() {
    setState(() {
      _showPause = !_showPause;
      _game.paused = _showPause;
    });
  }

  void _onPanStart(DragStartDetails d) {
    if (_showResult || _showPause) return;
    _dragOrigin = d.localPosition;
    if (_showHint) setState(() => _showHint = false);
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
    final t = L10n.of(context);
    return Scaffold(
      backgroundColor: Palette.outside,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: (_) => _onPanEnd(),
              onPanCancel: _onPanEnd,
              child: GameWidget(game: _game),
            ),
          ),
          ValueListenableBuilder<HudSnapshot>(
            valueListenable: _game.hud,
            builder: (context, snapshot, _) => GameHud(
              snapshot: snapshot,
              colorIndex: widget.colorIndex,
              onPause: _togglePause,
            ),
          ),
          if (_showHint && !_showResult)
            Align(
              alignment: const Alignment(0, 0.72),
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    t.dragToMove,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ),
          if (_showPause)
            _Overlay(
              child: GamePanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.pause,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GameButton(
                      label: t.resume,
                      icon: Icons.play_arrow_rounded,
                      color: Palette.head(widget.colorIndex),
                      onPressed: _togglePause,
                    ),
                    const SizedBox(height: 10),
                    GameButton(
                      label: t.menu,
                      icon: Icons.home_rounded,
                      color: const Color(0xFF6B7280),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          if (_showResult)
            _Overlay(
              child: ResultSheet(
                snapshot: _game.hud.value,
                deathCause: _game.sim.human.deathCause,
                colorIndex: widget.colorIndex,
                isRecord: _isRecord,
                bestPercent: widget.store.bestPercent,
                onPlayAgain: _restart,
                onMenu: () => Navigator.of(context).pop(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x8C101828),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: child,
          ),
        ),
      ),
    );
  }
}
