import 'package:flutter/material.dart';

import '../../game/logic/player_profile.dart';
import '../../game/render/avatar_painter.dart';

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
            fontFamilyFallback: avatarFontFallback,
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
    final color = accent ?? const Color(0xFF2E7BFF);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2.5,
          ),
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
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
