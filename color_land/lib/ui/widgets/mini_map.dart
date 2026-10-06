import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../game/logic/game_grid.dart';

import '../../game/render/color_land_game.dart';
import '../../game/render/palette.dart';
import '../theme/arcade.dart';

/// Butun xaritaning kichik ko'rinishi: kim qayerni egallagani, kamera
/// qayerga qaraganligi va o'yinchining joyi.
///
/// Panjara to'liq emas, `stride` qadam bilan o'qiladi va bir qatordagi
/// ketma-ket bir xil kataklar bitta to'rtburchak qilib chiziladi —
/// shuning uchun 250x250 xarita ham bir necha yuz chizish amaliga
/// tushadi. Qayta chizish HUD bilan bir xil tezlikda (~8/s) bo'ladi.
class MiniMap extends StatelessWidget {
  const MiniMap({super.key, required this.game, this.size = 96});

  final ColorLandGame game;
  final double size;

  /// Har nechanchi katak o'qiladi. 2 — xarita aniq, lekin ish hajmi
  /// to'rt barobar kam.
  static const int stride = 2;

  /// Egallangan hududlar — qator bo'ylab bir xil kataklarni birlashtirib
  /// chiziladi. Testlar tezligini shu yerda o'lchaydi.
  /// Chizilgan to'rtburchaklar sonini qaytaradi (o'lchov uchun).
  static int paintTerritories(
    Canvas canvas,
    GameGrid grid,
    Uint8List colorIndexById,
    Size size,
  ) {
    final sx = size.width / grid.width;
    final sy = size.height / grid.height;
    final owner = grid.owner;
    final paint = Paint()..isAntiAlias = false;
    var drawn = 0;
    for (var y = 0; y < grid.height; y += stride) {
      final row = y * grid.width;
      var x = 0;
      while (x < grid.width) {
        final id = owner[row + x];
        if (id == 0) {
          x += stride;
          continue;
        }
        var end = x + stride;
        while (end < grid.width && owner[row + end] == id) {
          end += stride;
        }
        paint.color = Palette.head(colorIndexById[id]);
        canvas.drawRect(
          Rect.fromLTRB(x * sx, y * sy, end * sx, (y + stride) * sy),
          paint,
        );
        drawn++;
        x = end;
      }
    }
    return drawn;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Arcade.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(Arcade.radiusSmall + 2),
        border: Border.all(color: Arcade.stroke),
        boxShadow: Arcade.panelShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Arcade.radiusSmall - 2),
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _MiniMapPainter(game: game, repaint: game.hud),
          ),
        ),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  _MiniMapPainter({required this.game, required Listenable repaint})
    : super(repaint: repaint);

  final ColorLandGame game;

  final Paint _fill = Paint()..isAntiAlias = false;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = game.sim.grid;
    final sx = size.width / grid.width;
    final sy = size.height / grid.height;

    canvas.drawRect(
      Offset.zero & size,
      _fill..color = Palette.outside.withValues(alpha: 0.85),
    );

    MiniMap.paintTerritories(
      canvas,
      game.sim.grid,
      game.sim.colorIndexById,
      size,
    );

    // Kamera ko'rayotgan joy.
    final view = game.camera.visibleWorldRect;
    final viewRect = Rect.fromLTRB(
      view.left / kCellSize * sx,
      view.top / kCellSize * sy,
      view.right / kCellSize * sx,
      view.bottom / kCellSize * sy,
    );
    canvas.drawRect(
      viewRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Arcade.text.withValues(alpha: 0.65),
    );

    // O'yinchi — yorqin nuqta, atrofida halqa.
    final human = game.sim.human;
    if (!human.alive) return;
    final at = Offset(human.x * sx, human.y * sy);
    canvas.drawCircle(at, 3.2, _fill..color = Colors.white);
    canvas.drawCircle(
      at,
      5.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Palette.head(human.colorIndex),
    );
  }

  @override
  bool shouldRepaint(_MiniMapPainter old) => true;
}
