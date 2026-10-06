import 'package:flutter/material.dart';

import '../../game/render/hud_snapshot.dart';
import '../../game/render/palette.dart';
import '../../i18n/l10n.dart';

/// O'yin ustidagi ma'lumot paneli: foiz, vaqt va top-5 reyting.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.snapshot,
    required this.colorIndex,
    required this.onPause,
  });

  final HudSnapshot snapshot;
  final int colorIndex;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        // Reyting maydonni to'smasligi uchun o'ng burchakka, tor ustunga
        // joylashtirilgan; chap tomonda esa o'yinchining o'z raqamlari.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PercentBadge(
                  percent: snapshot.percent,
                  colorIndex: colorIndex,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Pill(
                      icon: Icons.timer_outlined,
                      text: snapshot.formattedTime,
                    ),
                    const SizedBox(width: 6),
                    _Pill(icon: Icons.bolt_rounded, text: '${snapshot.kills}'),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _IconButtonSquare(icon: Icons.pause_rounded, onTap: onPause),
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
    );
  }
}

class _PercentBadge extends StatelessWidget {
  const _PercentBadge({required this.percent, required this.colorIndex});

  final double percent;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Palette.head(colorIndex),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Palette.territory(colorIndex),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '${percent.toStringAsFixed(2)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Palette.isDark
            ? const Color(0xD91B2133)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Palette.isDark
                ? const Color(0xFFB4BCC9)
                : const Color(0xFF4B5563),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Palette.isDark
                  ? const Color(0xFFF2F4F8)
                  : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButtonSquare extends StatelessWidget {
  const _IconButtonSquare({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.isDark
          ? const Color(0xD91B2133)
          : Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.pause_rounded, size: 20, color: Color(0xFF1F2937)),
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

  /// Tor ustun — maydonning ko'p qismi ochiq qoladi.
  static const double width = 150;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Palette.isDark
              ? const Color(0xD91B2133)
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9AA3B2),
                    ),
                  ),
                ),
                Text(
                  '$rank/$alive',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            for (var i = 0; i < rows.length; i++) _row(i + 1, rows[i]),
          ],
        ),
      ),
    );
  }

  Widget _row(int place, ScoreRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 11,
            child: Text(
              '$place',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB4BCC9),
              ),
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: Palette.head(r.colorIndex),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              r.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: r.isHuman ? FontWeight.w900 : FontWeight.w600,
                color: Palette.isDark
                    ? (r.isHuman
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFC3CAD6))
                    : (r.isHuman
                          ? const Color(0xFF111827)
                          : const Color(0xFF4B5563)),
              ),
            ),
          ),
          Text(
            '${r.percent.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Palette.isDark
                  ? const Color(0xFFE4E8EF)
                  : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
