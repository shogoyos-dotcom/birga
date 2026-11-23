import 'package:flutter/material.dart';

import '../game/logic/game_config.dart';
import '../game/logic/player_profile.dart';
import '../game/render/palette.dart';
import '../i18n/l10n.dart';
import '../services/audio_service.dart';
import '../services/continue_services.dart';
import '../storage/settings_store.dart';
import 'game_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'theme/arcade.dart';
import 'widgets/avatar_view.dart';
import 'widgets/shop_sheet.dart';
import 'widgets/ui_kit.dart';

/// Bosh menyu.
///
/// Kompozitsiya: yuqorida ixcham qator (beletlar, til), o'rtada o'yin
/// nomi + qisqa qoida + bitta katta "O'ynash" tugmasi, pastda esa
/// sozlamalar (rang, uslub, qiyinlik) alohida panelda. Shunda birinchi
/// ko'rinadigan narsa — o'yinni boshlash.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.store, this.audio});

  final SettingsStore store;

  /// Ovoz va vibratsiya. Berilmasa jim ishlaydi (testlarda shunday).
  final AudioService? audio;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _shop = DemoStoreService();

  /// Tanlovlar sozlamalar ekranida o'zgaradi — bu yerda faqat
  /// ko'rsatish uchun o'qiladi.
  int get _colorIndex => widget.store.colorIndex;

  late final AudioService _audio =
      widget.audio ??
      AudioService(
        musicEnabled: widget.store.musicEnabled,
        soundEnabled: widget.store.soundEnabled,
        vibrationEnabled: widget.store.vibrationEnabled,
      );

  Future<void> _openSettings() async {
    _audio.tap();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(store: widget.store, audio: _audio),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openShop() {
    _audio.tap();
    showDialog<void>(
      context: context,
      barrierColor: Arcade.scrim,
      builder: (_) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ShopSheet(
            store: _shop,
            colorIndex: _colorIndex,
            onPurchased: (count) async {
              await widget.store.addTickets(count);
              if (mounted) setState(() {});
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    _audio.tap();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileScreen(store: widget.store, colorIndex: _colorIndex),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _play() async {
    _audio.tap();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          config: GameConfig(difficulty: widget.store.difficulty),
          colorIndex: _colorIndex,
          store: widget.store,
          audio: _audio,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final accent = Palette.head(_colorIndex);

    return Scaffold(
      backgroundColor: Arcade.bg,
      body: _GridBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keng ekranda ustun o'rtada va cheklangan — satrlar
              // cho'zilib ketmasin.
              final wide = constraints.maxWidth > 620;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 24 : 18,
                  12,
                  wide ? 24 : 18,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 480,
                      // Kontent kam bo'lsa ham ustun ekran bo'yicha
                      // markazda tursin, tepaga yopishib qolmasin.
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            _TicketChip(
                              count: widget.store.tickets,
                              label: t.tickets,
                              onTap: _openShop,
                            ),
                            const Spacer(),
                            _IconChip(
                              icon: Icons.settings_rounded,
                              tooltip: t.settings,
                              onTap: _openSettings,
                            ),
                          ],
                        ),
                        SizedBox(height: wide ? 28 : 20),

                        // ——— Hero: nom, qoida, o'ynash ———
                        _Wordmark(colorIndex: _colorIndex),
                        const SizedBox(height: 14),
                        Text(
                          t.rulesShort,
                          textAlign: TextAlign.center,
                          style: Arcade.body,
                        ),
                        const SizedBox(height: 22),
                        GameButton(
                          label: t.play,
                          icon: Icons.play_arrow_rounded,
                          color: accent,
                          large: true,
                          onPressed: _play,
                        ),
                        const SizedBox(height: 14),
                        _ProfileCard(
                          nickname: widget.store.nickname ?? t.you,
                          avatar: widget.store.avatar,
                          label: t.profile,
                          colorIndex: _colorIndex,
                          onTap: _openProfile,
                        ),
                        const SizedBox(height: 10),
                        _RecordStrip(
                          label: t.record,
                          percent: widget.store.bestPercent,
                          kills: widget.store.bestKills,
                          killsLabel: t.kills,
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Fon: arcade panjarasi va yuqoridan tushadigan yengil yorug'lik.
class _GridBackdrop extends StatelessWidget {
  const _GridBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.75),
          radius: 1.1,
          colors: <Color>[Color(0xFF1C1733), Arcade.bg],
        ),
      ),
      child: CustomPaint(painter: _GridPainter(), child: child),
    );
  }
}

class _GridPainter extends CustomPainter {
  /// Fon panjarasining qadami (piksel).
  static const double step = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/// O'yin nomi: tanlangan rangda kichik kvadratlar va yozuv.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.colorIndex});

  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Palette.head((colorIndex + i) % Palette.colorCount),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: Arcade.glow(
                    Palette.head((colorIndex + i) % Palette.colorCount),
                    strength: 0.7,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'COLOR LAND',
          textAlign: TextAlign.center,
          style: Arcade.display,
        ),
      ],
    );
  }
}

/// Rekord: ikki raqam bitta ingichka panelda.
class _RecordStrip extends StatelessWidget {
  const _RecordStrip({
    required this.label,
    required this.percent,
    required this.kills,
    required this.killsLabel,
  });

  final String label;
  final double percent;
  final int kills;
  final String killsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Arcade.panel,
        borderRadius: BorderRadius.circular(Arcade.radius),
        border: Border.all(color: Arcade.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: StatTile(
              value: '${percent.toStringAsFixed(2)}%',
              label: label,
              color: Arcade.blueBright,
              compact: true,
            ),
          ),
          Container(width: 1, height: 34, color: Arcade.stroke),
          const SizedBox(width: 18),
          Expanded(
            child: StatTile(
              value: '$kills',
              label: killsLabel,
              color: Arcade.coral,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Beletlar soni; bosilsa do'kon ochiladi.
class _TicketChip extends StatelessWidget {
  const _TicketChip({
    required this.count,
    required this.label,
    required this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Arcade.panel,
      borderRadius: BorderRadius.circular(Arcade.radiusSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(Arcade.radiusSmall),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Arcade.radiusSmall),
            border: Border.all(color: Arcade.stroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.confirmation_number_rounded,
                size: 17,
                color: Arcade.gold,
              ),
              const SizedBox(width: 7),
              Text('$count', style: Arcade.numberSmall),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: Arcade.section),
              const SizedBox(width: 2),
              const Icon(Icons.add_rounded, size: 15, color: Arcade.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kichik kvadrat tugma (sozlamalar).
class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Arcade.panel,
        borderRadius: BorderRadius.circular(Arcade.radiusSmall),
        child: InkWell(
          borderRadius: BorderRadius.circular(Arcade.radiusSmall),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Arcade.radiusSmall),
              border: Border.all(color: Arcade.stroke),
            ),
            child: Icon(icon, size: 20, color: Arcade.text),
          ),
        ),
      ),
    );
  }
}

/// Profil kartasi: avatar + taxallus, bosilsa profil ekrani ochiladi.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.nickname,
    required this.avatar,
    required this.label,
    required this.colorIndex,
    required this.onTap,
  });

  final String nickname;
  final Avatar avatar;
  final String label;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Palette.head(colorIndex);
    return Material(
      color: Arcade.panel,
      borderRadius: BorderRadius.circular(Arcade.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Arcade.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Arcade.radius),
            border: Border.all(color: Arcade.stroke),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Arcade.surface,
                  borderRadius: BorderRadius.circular(Arcade.radiusSmall + 2),
                  border: Border.all(color: accent, width: 2),
                ),
                child: AvatarView(avatar: avatar, size: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: Arcade.section),
                    const SizedBox(height: 3),
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Arcade.text,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, color: Arcade.textFaint, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}
