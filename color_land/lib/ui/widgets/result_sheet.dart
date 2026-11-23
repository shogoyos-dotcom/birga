import 'package:flutter/material.dart';

import '../../game/logic/game_events.dart';
import '../../game/render/hud_snapshot.dart';
import '../../game/render/palette.dart';
import '../../i18n/l10n.dart';
import '../theme/arcade.dart';
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
    final accent = Palette.head(colorIndex);
    return GamePanel(
      accent: Arcade.coral,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.gameOver.toUpperCase(), style: Arcade.title),
          const SizedBox(height: 6),
          Text(
            t.deathReason(deathCause),
            textAlign: TextAlign.center,
            style: Arcade.body.copyWith(fontSize: 13),
          ),
          if (isRecord) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Arcade.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Arcade.radiusPill),
                border: Border.all(color: Arcade.gold.withValues(alpha: 0.5)),
              ),
              child: Text(
                '★  ${t.newRecord.toUpperCase()}',
                style: Arcade.section.copyWith(color: Arcade.gold),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Asosiy natija — eng katta raqam.
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${snapshot.percent.toStringAsFixed(2)}%',
                  label: t.territory,
                  color: accent,
                ),
              ),
              Expanded(
                child: StatTile(
                  value: '${snapshot.kills}',
                  label: t.kills,
                  color: Arcade.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Arcade.stroke),
          StatRow(label: t.time, value: snapshot.formattedTime),
          StatRow(label: t.record, value: '${bestPercent.toStringAsFixed(2)}%'),
          const SizedBox(height: 18),

          // Davom etish: belet yoki reklama.
          SectionLabel(t.continueGame),
          Row(
            children: [
              Expanded(
                child: tickets > 0
                    ? GameButton(
                        label: '${t.withTicket} ($tickets)',
                        icon: Icons.confirmation_number_rounded,
                        color: accent,
                        onPressed: onContinueWithTicket,
                      )
                    : GameButton(
                        label: t.buyTickets,
                        icon: Icons.shopping_bag_rounded,
                        color: accent,
                        onPressed: onOpenShop,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  // Reklama tayyor bo'lmasa ham bosiladi: o'yinchi
                  // sababini bilsin (tugma "o'lik" bo'lib qolmaydi).
                  label: t.watchAd,
                  icon: Icons.play_circle_fill_rounded,
                  color: adReady ? Arcade.mint : Arcade.textFaint,
                  onPressed: onContinueWithAd,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          GameButton(
            label: t.playAgain,
            icon: Icons.refresh_rounded,
            kind: ButtonKind.ghost,
            color: Arcade.coral,
            onPressed: onPlayAgain,
          ),
          const SizedBox(height: 10),
          GameButton(
            label: t.menu,
            icon: Icons.home_rounded,
            kind: ButtonKind.ghost,
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }
}
