import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/logic/game_config.dart';
import '../game/logic/match.dart';
import '../game/render/color_land_game.dart';
import '../game/render/hud_snapshot.dart';
import '../game/render/palette.dart';
import '../i18n/l10n.dart';
import '../services/continue_services.dart';
import '../storage/settings_store.dart';
import 'widgets/game_hud.dart';
import 'widgets/result_sheet.dart';
import 'widgets/shop_sheet.dart';
import 'theme/arcade.dart';
import 'widgets/ui_kit.dart';

/// O'yin ekrani: Flame tuvali + ustidan Flutter UI.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.config,
    required this.colorIndex,
    required this.store,
    this.ads,
    this.shop,
    this.random,
  });

  final GameConfig config;
  final int colorIndex;
  final SettingsStore store;

  /// Skrinshot va testlar uchun qat'iy tasodif manbai; odatda `null`.
  final math.Random? random;

  /// Reklama va do'kon xizmatlari. Berilmasa namuna variantlar ishlatiladi.
  final RewardedAdService? ads;
  final StoreService? shop;

  @override
  State<GameScreen> createState() => GameScreenState();
}

/// Testlar uchun ochiq — `gameForTest` orqali o'yinga kirish mumkin.
class GameScreenState extends State<GameScreen> {
  late ColorLandGame _game;

  /// Barmoq qo'yilgan nuqta — yo'nalish shu nuqtaga nisbatan hisoblanadi.
  Offset? _dragOrigin;

  late final RewardedAdService _ads = widget.ads ?? DemoRewardedAdService();
  late final StoreService _shop = widget.shop ?? DemoStoreService();

  /// O'limda bo'shagan kataklar — davom etilsa shular qaytariladi.
  List<int> _clearedOnDeath = const <int>[];

  bool _busy = false;
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
    // Taxallus profildan olinadi; kiritilmagan bo'lsa interfeys
    // tilidagi "Siz".
    _cachedName = widget.store.nickname ?? L10n.of(context).you;
    _game = _createGame();
  }

  ColorLandGame _createGame() {
    final sim = createMatch(
      config: widget.config,
      playerColorIndex: widget.colorIndex,
      playerName: _playerName,
      availableColors: Palette.colorCount,
      playerAvatar: widget.store.avatar,
      random: widget.random,
    );
    final game = ColorLandGame(sim: sim)..onHumanDeath = _onDeath;
    return game;
  }

  /// Interfeys tili o'zgarsa ham o'yin ichidagi nom o'zgarmasin —
  /// o'yin boshlanganda bir marta olinadi.
  String get _playerName => _cachedName ?? 'You';
  String? _cachedName;

  Future<void> _onDeath(List<int> clearedCells) async {
    _clearedOnDeath = clearedCells;
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

  /// Davom etish: o'yinchini tiklaydi va natija oynasini yopadi.
  Future<void> _resume() async {
    final ok = _game.sim.revive(_game.sim.human, _clearedOnDeath);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).noRoomToContinue)),
      );
      return;
    }
    setState(() {
      _showResult = false;
      _clearedOnDeath = const <int>[];
      _game.resumeAfterRevive();
    });
  }

  Future<void> _continueWithTicket() async {
    if (_busy) return;
    setState(() => _busy = true);
    final spent = await widget.store.spendTicket();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!spent) {
      _openShop();
      return;
    }
    await _resume();
  }

  Future<void> _continueWithAd() async {
    if (_busy) return;
    final t = L10n.of(context);
    if (!_ads.isReady) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.adNotReady)));
      return;
    }
    setState(() => _busy = true);
    final watched = await _ads.showRewarded();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!watched) return;
    await _resume();
  }

  void _openShop() {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x8C101828),
      builder: (dialogContext) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ShopSheet(
            store: _shop,
            colorIndex: widget.colorIndex,
            onPurchased: (count) async {
              await widget.store.addTickets(count);
              if (mounted) setState(() {});
            },
          ),
        ),
      ),
    );
  }

  void _restart() {
    setState(() {
      _showResult = false;
      _showPause = false;
      _showHint = true;
      _clearedOnDeath = const <int>[];
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
              game: _game,
            ),
          ),
          if (_showHint && !_showResult)
            Align(
              alignment: const Alignment(0, 0.72),
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Arcade.panel.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(Arcade.radius),
                    border: Border.all(
                      color: Arcade.blue.withValues(alpha: 0.5),
                    ),
                    boxShadow: Arcade.glow(Arcade.blue, strength: 0.7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        size: 18,
                        color: Arcade.blueBright,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.dragToMove,
                        style: Arcade.body.copyWith(
                          color: Arcade.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showPause)
            _Overlay(
              child: GamePanel(
                accent: Palette.head(widget.colorIndex),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.pause.toUpperCase(), style: Arcade.title),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            value:
                                '${_game.hud.value.percent.toStringAsFixed(2)}%',
                            label: t.territory,
                            color: Palette.head(widget.colorIndex),
                            compact: true,
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            value: _game.hud.value.formattedTime,
                            label: t.time,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                      kind: ButtonKind.ghost,
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
                tickets: widget.store.tickets,
                adReady: _ads.isReady,
                onContinueWithTicket: _continueWithTicket,
                onContinueWithAd: _continueWithAd,
                onOpenShop: _openShop,
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
        color: Arcade.scrim,
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
