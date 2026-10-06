import 'package:flutter/material.dart';

import '../game/logic/difficulty.dart';
import '../game/logic/game_config.dart';
import '../game/render/game_theme.dart';
import '../game/render/palette.dart';
import '../i18n/app_language.dart';
import '../i18n/l10n.dart';
import '../game/logic/player_profile.dart';
import '../storage/settings_store.dart';
import '../services/continue_services.dart';
import 'game_screen.dart';
import 'profile_screen.dart';
import 'widgets/avatar_view.dart';
import 'widgets/shop_sheet.dart';
import 'widgets/ui_kit.dart';

/// Bosh menyu: o'ynash, rang tanlash, qiyinlik, til va rekord.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.store});

  final SettingsStore store;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late int _colorIndex = widget.store.colorIndex;
  late Difficulty _difficulty = widget.store.difficulty;
  late GameTheme _theme = widget.store.theme;
  final StoreService _shop = DemoStoreService();

  void _openShop() {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x8C101828),
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileScreen(store: widget.store, colorIndex: _colorIndex),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _play() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          config: GameConfig(difficulty: _difficulty),
          colorIndex: _colorIndex,
          store: widget.store,
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
      backgroundColor: Palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 44,
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
                        accent: accent,
                        onTap: _openShop,
                      ),
                      const Spacer(),
                      _LanguageMenu(store: widget.store),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _Logo(colorIndex: _colorIndex),
                  const SizedBox(height: 18),
                  _ProfileCard(
                    nickname: widget.store.nickname ?? t.you,
                    avatar: widget.store.avatar,
                    label: t.profile,
                    colorIndex: _colorIndex,
                    onTap: _openProfile,
                  ),
                  const SizedBox(height: 14),
                  _RecordCard(
                    label: t.record,
                    percent: widget.store.bestPercent,
                    kills: widget.store.bestKills,
                    killsLabel: t.kills,
                    accent: accent,
                  ),
                  const SizedBox(height: 18),
                  GameButton(
                    label: t.play,
                    icon: Icons.play_arrow_rounded,
                    color: accent,
                    onPressed: _play,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(t.chooseColor),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < Palette.colorCount; i++)
                        ColorChip(
                          index: i,
                          selected: i == _colorIndex,
                          onTap: () {
                            setState(() => _colorIndex = i);
                            widget.store.setColorIndex(i);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(t.themeLabel),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final th in GameTheme.all) ...[
                        Expanded(
                          child: _ChoiceButton(
                            label: th.name,
                            selected: th.id == _theme.id,
                            accent: accent,
                            onTap: () {
                              setState(() {
                                _theme = th;
                                Palette.theme = th;
                              });
                              widget.store.setTheme(th);
                            },
                          ),
                        ),
                        if (th != GameTheme.all.last) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(t.difficulty),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final d in Difficulty.values) ...[
                        Expanded(
                          child: _ChoiceButton(
                            label: t.difficultyName(d),
                            selected: d == _difficulty,
                            accent: accent,
                            onTap: () {
                              setState(() => _difficulty = d);
                              widget.store.setDifficulty(d);
                            },
                          ),
                        ),
                        if (d != Difficulty.values.last)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.colorIndex});

  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.rotate(
                    angle: (i.isEven ? 1 : -1) * 0.08,
                    child: Container(
                      width: 40,
                      height: 40 + i * 6.0,
                      decoration: BoxDecoration(
                        color: Palette.head(
                          (colorIndex + i * 3) % Palette.colorCount,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.territory(
                              (colorIndex + i * 3) % Palette.colorCount,
                            ),
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'COLOR LAND',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.label,
    required this.percent,
    required this.kills,
    required this.killsLabel,
    required this.accent,
  });

  final String label;
  final double percent;
  final int kills;
  final String killsLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${percent.toStringAsFixed(2)}%', label, accent),
          Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),
          _stat('$kills', killsLabel, const Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9AA3B2),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: Color(0xFF9AA3B2),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

/// Beletlar soni va do'konga kirish.
class _TicketChip extends StatelessWidget {
  const _TicketChip({
    required this.count,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final int count;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.confirmation_number_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                '\$count',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9AA3B2),
                ),
              ),
              const Icon(Icons.add_rounded, size: 16, color: Color(0xFF9AA3B2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Til kodi uchun kichik yorliq.
class _LangBadge extends StatelessWidget {
  const _LangBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }
}

/// Til tanlash menyusi.
class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.store});

  final SettingsStore store;

  @override
  Widget build(BuildContext context) {
    final controller = L10n.controllerOf(context);
    return PopupMenuButton<AppLanguage>(
      initialValue: controller.language,
      onSelected: controller.setLanguage,
      tooltip: L10n.of(context).language,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final l in AppLanguage.values)
          PopupMenuItem<AppLanguage>(
            value: l,
            child: Row(
              children: [
                _LangBadge(text: l.badge),
                const SizedBox(width: 10),
                Text(l.nativeName),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangBadge(text: controller.language.badge),
            const SizedBox(width: 8),
            Text(
              controller.language.nativeName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Bosh menyudagi profil kartasi: avatar + taxallus, bosilsa profil ochiladi.
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Palette.territory(colorIndex),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: accent, width: 2.5),
                ),
                child: AvatarView(avatar: avatar, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
