import 'package:flutter/material.dart';

import '../../game/logic/game_events.dart';
import '../../game/render/hud_snapshot.dart';
import '../../game/render/palette.dart';
import '../../i18n/l10n.dart';
import 'ui_kit.dart';

/// O'yin tugaganda chiqadigan natija oynasi.
class ResultSheet extends StatelessWidget {
  const ResultSheet({
    super.key,
    required this.snapshot,
    required this.deathCause,
    required this.colorIndex,
    required this.isRecord,
    required this.bestPercent,
    required this.onPlayAgain,
    required this.onMenu,
  });

  final HudSnapshot snapshot;
  final DeathCause deathCause;
  final int colorIndex;
  final bool isRecord;
  final double bestPercent;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return GamePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.gameOver,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            t.deathReason(deathCause),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          if (isRecord) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4CC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '⭐  ${t.newRecord}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A6D00),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          StatRow(
            label: t.territory,
            value: '${snapshot.percent.toStringAsFixed(2)}%',
            highlight: true,
          ),
          StatRow(label: t.kills, value: '${snapshot.kills}'),
          StatRow(label: t.time, value: snapshot.formattedTime),
          StatRow(label: t.record, value: '${bestPercent.toStringAsFixed(2)}%'),
          const SizedBox(height: 18),
          GameButton(
            label: t.playAgain,
            icon: Icons.refresh_rounded,
            color: Palette.head(colorIndex),
            onPressed: onPlayAgain,
          ),
          const SizedBox(height: 10),
          GameButton(
            label: t.menu,
            icon: Icons.home_rounded,
            color: const Color(0xFF6B7280),
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }
}
