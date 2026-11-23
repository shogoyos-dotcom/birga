import 'package:flutter/material.dart';

import '../../game/render/color_land_game.dart';
import '../../game/render/hud_snapshot.dart';
import '../../game/render/palette.dart';
import '../../i18n/l10n.dart';
import '../theme/arcade.dart';
import 'avatar_view.dart';
import 'mini_map.dart';

/// O'yin ustidagi ma'lumot qatlami.
///
/// Joylashuv ataylab chekkalarga surilgan: yuqorida bitta ixcham qator
/// (foiz, vaqt, o'ldirishlar, pauza), o'ng tomonda tor reyting, pastki
/// chap burchakda mini-xarita. Arenaning o'rtasi — eng muhim joy —
/// hech narsa bilan to'silmaydi.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.snapshot,
    required this.colorIndex,
    required this.onPause,
    this.game,
  });

  final HudSnapshot snapshot;
  final int colorIndex;
  final VoidCallback onPause;

  /// Mini-xarita uchun. Berilmasa xarita ko'rsatilmaydi.
  final ColorLandGame? game;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final accent = Palette.head(colorIndex);

    return SafeArea(
      child: Stack(
        children: [
          // Yuqori qator.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScoreBar(percent: snapshot.percent, accent: accent),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Pill(
                            icon: Icons.timer_outlined,
                            text: snapshot.formattedTime,
                          ),
                          const SizedBox(width: 6),
                          _Pill(
                            icon: Icons.bolt_rounded,
                            text: '${snapshot.kills}',
                            color: Arcade.coral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _SquareButton(
                      icon: Icons.pause_rounded,
                      onTap: onPause,
                      tooltip: t.pause,
                    ),
                    const SizedBox(height: 8),
                    _Leaderboard(
                      title: t.leaderboard,
                      rows: snapshot.top,
                      rank: snapshot.rank,
                      alive: snapshot.alivePlayers,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Mini-xarita — pastki chap burchak, boshqaruvga xalaqit bermaydi.
          if (game != null)
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 0, 14),
                child: IgnorePointer(child: MiniMap(game: game!)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Egallangan foiz: yirik raqam va ostida to'ldiruvchi chiziq.
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.percent, required this.accent});

  final double percent;
  final Color accent;

  /// Chiziq to'lishi uchun mo'ljal — amalda 20% ham katta natija.
  static const double fullAt = 25;

  @override
  Widget build(BuildContext context) {
    final fill = (percent / fullAt).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
      decoration: BoxDecoration(
        color: Arcade.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(Arcade.radiusSmall + 2),
        border: Border.all(color: Arcade.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percent.toStringAsFixed(2)}%',
            style: Arcade.number.copyWith(fontSize: 26, color: accent),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 112,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(height: 5, color: Arcade.surface),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        boxShadow: Arcade.glow(accent, strength: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Arcade.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(Arcade.radiusSmall),
        border: Border.all(color: Arcade.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color ?? Arcade.textDim),
          const SizedBox(width: 5),
          Text(text, style: Arcade.numberSmall),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Arcade.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(Arcade.radiusSmall),
        child: InkWell(
          borderRadius: BorderRadius.circular(Arcade.radiusSmall),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(9),
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

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({
    required this.title,
    required this.rows,
    required this.rank,
    required this.alive,
  });

  final String title;
  final List<ScoreRow> rows;
  final int rank;
  final int alive;

  /// Tor ustun — arenaning ko'p qismi ochiq qoladi.
  static const double width = 152;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
        decoration: BoxDecoration(
          color: Arcade.panel.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(Arcade.radiusSmall + 2),
          border: Border.all(color: Arcade.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: Arcade.section.copyWith(fontSize: 9),
                  ),
                ),
                Text(
                  '$rank/$alive',
                  style: Arcade.section.copyWith(
                    fontSize: 9,
                    color: Arcade.blueBright,
                  ),
                ),
              ],
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: Arcade.stroke,
            ),
            for (var i = 0; i < rows.length; i++) _row(i + 1, rows[i]),
          ],
        ),
      ),
    );
  }

  Widget _row(int place, ScoreRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: Text(
              '$place',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: r.isHuman ? Arcade.blueBright : Arcade.textFaint,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Palette.head(r.colorIndex),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          AvatarView(avatar: r.avatar, size: 14),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              r.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: r.isHuman ? FontWeight.w900 : FontWeight.w600,
                color: r.isHuman ? Arcade.text : Arcade.textDim,
              ),
            ),
          ),
          Text(
            '${r.percent.toStringAsFixed(1)}%',
            style: Arcade.numberSmall.copyWith(
              fontSize: 11,
              color: r.isHuman ? Arcade.text : Arcade.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
