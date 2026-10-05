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
    required this.tickets,
    required this.adReady,
    required this.onContinueWithTicket,
    required this.onContinueWithAd,
    required this.onOpenShop,
  });

  final HudSnapshot snapshot;
  final DeathCause deathCause;
  final int colorIndex;
  final bool isRecord;
  final double bestPercent;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  /// Qolgan beletlar soni.
  final int tickets;
  final bool adReady;
  final VoidCallback onContinueWithTicket;
  final VoidCallback onContinueWithAd;
  final VoidCallback onOpenShop;

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

          // Davom etish: belet yoki reklama.
          Text(
            t.continueGame,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF9AA3B2),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: tickets > 0
                    ? GameButton(
                        label: '${t.withTicket} ($tickets)',
                        icon: Icons.confirmation_number_rounded,
                        color: Palette.head(colorIndex),
                        onPressed: onContinueWithTicket,
                      )
                    : GameButton(
                        label: t.buyTickets,
                        icon: Icons.shopping_bag_rounded,
                        color: Palette.head(colorIndex),
                        onPressed: onOpenShop,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: t.watchAd,
                  icon: Icons.play_circle_fill_rounded,
                  color: adReady
                      ? const Color(0xFF14C38E)
                      : const Color(0xFF9AA3B2),
                  onPressed: onContinueWithAd,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          GameButton(
            label: t.playAgain,
            icon: Icons.refresh_rounded,
            color: const Color(0xFF4B5563),
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
