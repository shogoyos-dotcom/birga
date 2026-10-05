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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _PercentBadge(
                  percent: snapshot.percent,
                  colorIndex: colorIndex,
                ),
                const SizedBox(width: 10),
                _Pill(icon: Icons.timer_outlined, text: snapshot.formattedTime),
                const SizedBox(width: 8),
                _Pill(icon: Icons.bolt_rounded, text: '${snapshot.kills}'),
                const SizedBox(width: 8),
                _Pill(
                  icon: Icons.leaderboard_rounded,
                  text: '${snapshot.rank}/${snapshot.alivePlayers}',
                ),
                const Spacer(),
                _IconButtonSquare(icon: Icons.pause_rounded, onTap: onPause),
              ],
            ),
            const SizedBox(height: 10),
            _Leaderboard(title: t.leaderboard, rows: snapshot.top),
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
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4B5563)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
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
      color: Colors.white.withValues(alpha: 0.94),
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
  const _Leaderboard({required this.title, required this.rows});

  final String title;
  final List<ScoreRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9AA3B2),
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < rows.length; i++) _row(i + 1, rows[i]),
        ],
      ),
    );
  }

  Widget _row(int place, ScoreRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$place',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9AA3B2),
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Palette.head(r.colorIndex),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              r.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: r.isHuman ? FontWeight.w900 : FontWeight.w600,
                color: r.isHuman
                    ? const Color(0xFF111827)
                    : const Color(0xFF4B5563),
              ),
            ),
          ),
          Text(
            '${r.percent.toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
