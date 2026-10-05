import 'package:flutter/material.dart';

import '../../game/render/palette.dart';
import '../../i18n/l10n.dart';
import '../../services/continue_services.dart';
import 'ui_kit.dart';

/// Belet sotib olish oynasi.
///
/// Xaridni [StoreService] bajaradi — hozircha namuna variant, haqiqiy
/// Play Billing ulangach bu ekran o'zgarmaydi.
class ShopSheet extends StatefulWidget {
  const ShopSheet({
    super.key,
    required this.store,
    required this.colorIndex,
    required this.onPurchased,
  });

  final StoreService store;
  final int colorIndex;

  /// Xarid muvaffaqiyatli bo'lganda olingan beletlar soni bilan chaqiriladi.
  final Future<void> Function(int tickets) onPurchased;

  @override
  State<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<ShopSheet> {
  List<TicketPack>? _packs;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    widget.store.packs().then((p) {
      if (mounted) setState(() => _packs = p);
    });
  }

  Future<void> _buy(TicketPack pack) async {
    setState(() => _busyId = pack.id);
    final got = await widget.store.buy(pack);
    if (!mounted) return;
    setState(() => _busyId = null);
    final t = L10n.of(context);
    if (got <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.purchaseFailed)));
      return;
    }
    await widget.onPurchased(got);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${t.ticketsAdded}: +$got')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final accent = Palette.head(widget.colorIndex);
    final packs = _packs;

    return GamePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.shop,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            t.demoPurchaseNote,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
          ),
          const SizedBox(height: 16),
          if (packs == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else
            for (final pack in packs) ...[
              _PackRow(
                pack: pack,
                label: '${pack.tickets} ${t.ticketPack}',
                accent: accent,
                busy: _busyId == pack.id,
                onTap: _busyId == null ? () => _buy(pack) : null,
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 8),
          GameButton(
            label: t.close,
            color: const Color(0xFF6B7280),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({
    required this.pack,
    required this.label,
    required this.accent,
    required this.busy,
    required this.onTap,
  });

  final TicketPack pack;
  final String label;
  final Color accent;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: pack.bestValue ? accent.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: pack.bestValue ? accent : const Color(0xFFE5E7EB),
              width: pack.bestValue ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.confirmation_number_rounded, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  pack.price,
                  style: TextStyle(fontWeight: FontWeight.w900, color: accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
