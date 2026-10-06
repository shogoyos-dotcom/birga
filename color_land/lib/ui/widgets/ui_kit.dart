import 'package:flutter/material.dart';

import '../../game/render/palette.dart';
import '../theme/arcade.dart';

/// Tugma turi.
enum ButtonKind {
  /// To'ldirilgan, asosiy harakat.
  primary,

  /// Panel rangidagi, chekkasi chizilgan ikkinchi darajali harakat.
  ghost,
}

/// O'yin uslubidagi tugma: aniq holatlar, yengil soya va bosilganda
/// qisqa animatsiya (pastga suriladi, soyasi yo'qoladi).
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
    this.kind = ButtonKind.primary,
    this.enabled = true,
    this.large = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback onPressed;

  /// Asosiy rang; berilmasa elektr ko'k.
  final Color? color;
  final IconData? icon;
  final ButtonKind kind;
  final bool enabled;

  /// Bosh menyudagi "O'ynash" kabi katta tugma.
  final bool large;
  final bool expanded;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;
  bool _hover = false;

  /// Bosilganda tugma shuncha pastga tushadi (soya balandligi).
  static const double _lift = 4;

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? Arcade.blue;
    final on = widget.enabled;
    final primary = widget.kind == ButtonKind.primary;
    // Rangsiz "ghost" — eng past darajadagi harakat (masalan "Menyu"):
    // chekkasi ham, yozuvi ham bo'g'iq bo'ladi.
    final neutral = !primary && widget.color == null;

    final fill = !on
        ? Arcade.surface
        : primary
        ? (_hover ? Color.lerp(base, Colors.white, 0.12)! : base)
        : (_hover ? Arcade.surface : Arcade.panel);
    final labelColor = !on
        ? Arcade.textFaint
        : primary
        ? Colors.white
        : neutral
        ? Arcade.textDim
        : Arcade.text;
    final edge = !on || neutral
        ? Arcade.stroke
        : primary
        ? Color.lerp(base, Colors.black, 0.35)!
        : base.withValues(alpha: 0.55);

    final radius = BorderRadius.circular(
      widget.large ? Arcade.radius + 2 : Arcade.radius,
    );
    final pressed = _down && on;

    return MouseRegion(
      cursor: on ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: on ? (_) => _set(true) : null,
        onTapUp: on ? (_) => _set(false) : null,
        onTapCancel: on ? () => _set(false) : null,
        onTap: on ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, pressed ? _lift : 0, 0),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: <BoxShadow>[
              // "Qalinlik": tugma yuzasi ostidagi to'q qatlam.
              if (on && !pressed)
                BoxShadow(color: edge, offset: const Offset(0, _lift)),
              if (on && primary && !pressed)
                ...Arcade.glow(base, strength: 0.8),
            ],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 28 : 20,
              vertical: widget.large ? 20 : 14,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: Border.all(
                color: primary ? Colors.transparent : edge,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: widget.expanded
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: labelColor,
                    size: widget.large ? 24 : 19,
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Arcade.button.copyWith(
                      color: labelColor,
                      fontSize: widget.large ? 20 : 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// To'q panel: chekkasi chizilgan, yumaloq burchakli yuza.
class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accent,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Berilsa, panel tepasida shu rangda ingichka chiziq chiziladi.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Arcade.panel,
        borderRadius: BorderRadius.circular(Arcade.radius + 4),
        border: Border.all(color: Arcade.stroke),
        boxShadow: Arcade.panelShadow,
      ),
      child: child,
    );
    if (accent == null) return body;
    return Stack(
      children: [
        body,
        Positioned(
          left: 24,
          right: 24,
          top: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: Arcade.glow(accent!),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bo'lim sarlavhasi: kichik, katta harflar, siyrak oraliq.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Arcade.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(child: Text(text.toUpperCase(), style: Arcade.section)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Yirik raqam + ostida kichik yozuv.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.compact = false,
  });

  final String value;
  final String label;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          style: Arcade.number.copyWith(
            color: color ?? Arcade.text,
            fontSize: compact ? 20 : 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: Arcade.section),
      ],
    );
  }
}

/// Sarlavha + qiymat qatori (natija oynasi uchun).
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: Arcade.section.copyWith(color: Arcade.textDim),
          ),
          Text(
            value,
            style: highlight
                ? Arcade.number.copyWith(fontSize: 22, color: Arcade.blueBright)
                : Arcade.numberSmall,
          ),
        ],
      ),
    );
  }
}

/// Rang tanlash katakchasi.
class ColorChip extends StatelessWidget {
  const ColorChip({
    super.key,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Palette.head(index);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Arcade.radiusSmall),
          border: Border.all(
            color: selected ? Arcade.text : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected ? Arcade.glow(color) : null,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

/// Bir nechta variantdan bittasini tanlash (uslub, qiyinlik).
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          _Chip(
            label: labelOf(v),
            selected: v == selected,
            onTap: () => onSelected(v),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Arcade.blue : Arcade.surface,
      borderRadius: BorderRadius.circular(Arcade.radiusSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(Arcade.radiusSmall),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Arcade.radiusSmall),
            border: Border.all(
              color: selected ? Arcade.blueBright : Arcade.stroke,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: selected ? Colors.white : Arcade.textDim,
            ),
          ),
        ),
      ),
    );
  }
}
