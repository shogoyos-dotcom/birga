import 'package:flutter/material.dart';

import '../../game/logic/player_profile.dart';
import '../../game/render/avatar_painter.dart';
import '../../game/render/canvas_text.dart';
import '../theme/arcade.dart';

/// Avatarni interfeysda ko'rsatadi.
///
/// Emoji va bayroqlar matn sifatida (tizim emoji shriftidan), odam
/// tasvirlari esa [AvatarPainter] bilan chiziladi — ikkalasi ham rasm
/// fayllarini talab qilmaydi.
class AvatarView extends StatelessWidget {
  const AvatarView({super.key, required this.avatar, this.size = 44});

  final Avatar avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatar.kind == AvatarKind.figure) {
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _FigurePainter(avatar)),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Text(
          avatar.glyph,
          style: TextStyle(
            fontSize: size * 0.72,
            fontFamilyFallback: canvasFontFallback,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.avatar);

  final Avatar avatar;
  static final AvatarPainter _painter = AvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _painter.paint(
      canvas,
      avatar,
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.92,
    );
  }

  @override
  bool shouldRepaint(_FigurePainter old) => old.avatar != avatar;
}

/// Tanlanganini ko'rsatadigan, bosiladigan avatar katakchasi.
class AvatarChip extends StatelessWidget {
  const AvatarChip({
    super.key,
    required this.avatar,
    required this.selected,
    required this.onTap,
    this.accent,
    this.caption,
  });

  final Avatar avatar;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  /// Katakcha ostidagi kichik yozuv (bayroqlar uchun davlat nomi).
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Arcade.blue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Arcade.surface,
          borderRadius: BorderRadius.circular(Arcade.radiusSmall + 2),
          border: Border.all(
            color: selected ? color : Arcade.stroke,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected ? Arcade.glow(color, strength: 0.6) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarView(avatar: avatar, size: 40),
            if (caption != null)
              SizedBox(
                width: 54,
                child: Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: Arcade.textDim,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
