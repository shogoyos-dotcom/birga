import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../logic/game_grid.dart';
import '../logic/player_profile.dart';
import 'avatar_painter.dart';
import 'contour.dart';
import '../logic/player_state.dart';
import 'palette.dart';

/// Hududni kataklar emas, silliq shakl sifatida chizadi.
///
/// Usul: hududning haqiqiy chegara chizig'i topiladi ([ContourBuilder]) va
/// Chaikin usuli bilan silliqlanadi. Shuning uchun pog'onali chekkalar
/// qolmaydi, teshiklar esa (ichkarida qolgan begona soha) o'z-o'zidan
/// kesib tashlanadi.
///
/// Har bir o'yinchi shakli `ui.Picture` sifatida keshlanadi va faqat
/// o'sha o'yinchi hududi o'zgarganda qayta yoziladi.
class TerritoryShapes {
  TerritoryShapes(this.grid, this.cellSize);

  /// Avatar naqshini chizuvchi — hudud keshi bilan birga yoziladi,
  /// shuning uchun har kadrda emas, faqat hudud o'zgarganda ishlaydi.
  final AvatarPainter _avatars = AvatarPainter();

  /// Chegarani necha marta silliqlash. Ko'proq = yumaloqroq, lekin
  /// nuqtalar soni har safar ikki barobar oshadi.
  static const int smoothPasses = 2;

  /// Pog'onalarni to'g'ri chiziqqa aylantirish chegarasi (katak ulushi).
  static const double simplifyTolerance = 0.8;

  /// Hudud "qalinligi" uslubdan olinadi — shakl pastga shuncha surilib,
  /// to'q rangda chiziladi.
  static double get depthFactor => Palette.depthFactor;

  final GameGrid grid;
  final double cellSize;

  final Map<int, _Cached> _cache = <int, _Cached>{};

  /// Oxirgi kadrda nechta shakl qayta yozilgani (profil uchun).
  int lastRebuildCount = 0;

  /// Avatar uchun joy: hudud markazi va unga sig'adigan o'lcham.
  /// Shakl bilan birga, faqat hudud o'zgarganda hisoblanadi.
  AvatarSlot? slotOf(int playerId) => _cache[playerId]?.slot;

  int get cachedCount => _cache.length;

  void render(ui.Canvas canvas, Iterable<PlayerState> players, Rect visible) {
    lastRebuildCount = 0;
    // Pastdagi hudud keyinroq chiziladi — uning yon devori yuqoridagini
    // to'g'ri qoplaydi.
    final ordered = players.toList()
      ..sort((a, bPlayer) {
        final ba = grid.boundsOf(a.id);
        final bb = grid.boundsOf(bPlayer.id);
        return (ba?.$4 ?? -1).compareTo(bb?.$4 ?? -1);
      });
    for (final p in ordered) {
      final bounds = grid.boundsOf(p.id);
      if (bounds == null) continue;
      final worldBounds = Rect.fromLTRB(
        bounds.$1 * cellSize,
        bounds.$2 * cellSize,
        (bounds.$3 + 1) * cellSize,
        (bounds.$4 + 1) * cellSize,
      );
      if (!worldBounds.overlaps(visible)) continue;

      final version = grid.versionOf(p.id);
      var cached = _cache[p.id];
      if (cached == null || cached.version != version) {
        cached?.picture.dispose();
        cached = _Cached(
          version,
          _record(p.id, p.colorIndex, bounds, p.avatar),
          _avatarSlot(p.id, bounds),
        );
        _cache[p.id] = cached;
        lastRebuildCount++;
      }
      canvas.drawPicture(cached.picture);
    }
  }

  ui.Picture _record(
    int playerId,
    int colorIndex,
    (int, int, int, int) b,
    Avatar avatar,
  ) {
    final recorder = ui.PictureRecorder();
    final cull = Rect.fromLTRB(
      b.$1 * cellSize - cellSize,
      b.$2 * cellSize - cellSize,
      (b.$3 + 1) * cellSize + cellSize,
      (b.$4 + 1) * cellSize + cellSize * 3,
    );
    final canvas = ui.Canvas(recorder, cull);
    final path = buildPath(grid, playerId, b, cellSize);
    final depth = cellSize * depthFactor;

    // 1. Yerga tushgan soya. Blur ataylab ishlatilmaydi — u GPU da
    // qimmat va kuchsiz telefonda sezilarli sekinlashtiradi; o'rniga
    // shaklning pastga surilgan shaffof nusxasi chiziladi.
    canvas.drawPath(
      path.shift(Offset(0, depth * 1.9)),
      Paint()
        ..color = Palette.groundShadow
        ..isAntiAlias = true,
    );
    // 2. Yon devor: shaklning pastga surilgan nusxasi.
    canvas.drawPath(
      path.shift(Offset(0, depth)),
      Paint()
        ..color = Palette.side(colorIndex)
        ..isAntiAlias = true,
    );
    // 3. Ustki yuza.
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.territory(colorIndex)
        ..isAntiAlias = true,
    );
    // 4. Avatar naqshi — butun hudud bo'ylab, shakl ichiga kesilgan.
    _paintAvatarPattern(canvas, path, b, avatar);
    return recorder.endRecording();
  }

  /// Avatarni hududning hamma yeriga takrorlab chizadi.
  ///
  /// Naqsh hudud shakliga kesiladi, shuning uchun chetidan chiqmaydi.
  /// Katak o'lchami hudud kattaligiga qarab tanlanadi — kichik hududda
  /// bir-ikkita, kattasida ko'proq belgi tushadi, lekin soni
  /// [maxPatternTiles] dan oshmaydi.
  void _paintAvatarPattern(
    ui.Canvas canvas,
    Path shape,
    (int, int, int, int) b,
    Avatar avatar,
  ) {
    final layout = patternLayout(
      (b.$3 - b.$1 + 1) * cellSize,
      (b.$4 - b.$2 + 1) * cellSize,
      cellSize,
    );
    if (layout == null) return;
    final step = layout.step;

    canvas.save();
    canvas.clipPath(shape);
    canvas.saveLayer(shape.getBounds(), Paint()..color = patternColor);
    final left = b.$1 * cellSize;
    final top = b.$2 * cellSize;
    for (var row = 0; row < layout.rows; row++) {
      // Toq qatorlar yarim qadamga suriladi — naqsh jonliroq ko'rinadi.
      final dx = row.isOdd ? step / 2 : 0.0;
      for (var col = 0; col < layout.cols; col++) {
        _avatars.paint(
          canvas,
          avatar,
          Offset(left + col * step + dx, top + row * step),
          step * 0.82,
        );
      }
    }
    canvas.restore();
    canvas.restore();
  }

  /// Naqsh qadami va belgilar sonini hisoblaydi (testlar ham chaqiradi).
  ///
  /// Qadam hudud kattaligidan kelib chiqadi, lekin ikki tomondan
  /// cheklanadi: belgi juda mayda yoki juda yirik bo'lmasin, va umumiy
  /// soni [maxPatternTiles] dan oshmasin.
  static PatternLayout? patternLayout(double w, double h, double cellSize) {
    if (w <= 0 || h <= 0) return null;
    var step = (w < h ? w : h) / 2.4;
    final minStep = cellSize * patternMinCells;
    final maxStep = cellSize * patternMaxCells;
    if (step < minStep) step = minStep;
    if (step > maxStep) step = maxStep;

    var cols = (w / step).ceil() + 1;
    var rows = (h / step).ceil() + 1;
    while (cols * rows > maxPatternTiles) {
      step *= 1.3;
      cols = (w / step).ceil() + 1;
      rows = (h / step).ceil() + 1;
    }
    return PatternLayout(step, cols, rows);
  }

  /// Naqsh belgisi hudud rangini bosib ketmasligi uchun shaffoflik.
  static const Color patternColor = Color(0xBFFFFFFF);

  /// Naqsh qadami chegaralari (katak hisobida).
  static const double patternMinCells = 2.6;
  static const double patternMaxCells = 9.0;

  /// Bitta hududga tushadigan belgilar soni chegarasi — juda katta
  /// hududda ham shakl yozish narxi nazoratda qolsin.
  static const int maxPatternTiles = 400;

  /// Hudud ichidan avatar uchun joy topadi.
  AvatarSlot? _avatarSlot(int playerId, (int, int, int, int) b) =>
      computeAvatarSlot(grid, playerId, b, cellSize);

  /// Avatar joyini hisoblaydi (testlar ham shuni chaqiradi).
  ///
  /// Avatar hududning eng "qalin" nuqtasiga qo'yiladi: har bir o'z
  /// katagi uchun begona katakkacha masofa topiladi (masofa
  /// transformatsiyasi, ikki o'tishda) va eng kattasi tanlanadi. Shuning
  /// uchun yarim oysimon yoki teshikli hududda ham avatar ingichka
  /// chekkaga tushib qolmaydi; o'lchami esa shu nuqtaga sig'adigan
  /// doiradan olinadi.
  ///
  /// Tenglikda hududning o'rta nuqtasiga yaqinrog'i tanlanadi — shunda
  /// avatar hudud o'sganda sakrab yurmaydi.
  static AvatarSlot? computeAvatarSlot(
    GameGrid grid,
    int playerId,
    (int, int, int, int) b,
    double cellSize,
  ) {
    final owner = grid.owner;
    final gw = grid.width;
    final x0 = b.$1, y0 = b.$2, x1 = b.$3, y1 = b.$4;
    final w = x1 - x0 + 1, h = y1 - y0 + 1;
    if (w <= 0 || h <= 0) return null;

    // 1. O'z kataklari va o'rta nuqta.
    final dist = Int32List(w * h);
    var sumX = 0, sumY = 0, count = 0;
    for (var y = 0; y < h; y++) {
      final row = (y + y0) * gw;
      for (var x = 0; x < w; x++) {
        if (owner[row + x + x0] == playerId) {
          dist[y * w + x] = _far;
          sumX += x;
          sumY += y;
          count++;
        }
      }
    }
    if (count < minCellsForAvatar) return null;
    final mx = sumX / count, my = sumY / count;

    // 2. Masofa transformatsiyasi. Qutidan tashqarisi begona hisoblanadi,
    // shuning uchun chekka kataklar masofasi 1 dan boshlanadi.
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if (dist[i] == 0) continue;
        var best = x == 0 ? 1 : dist[i - 1] + 1;
        final up = y == 0 ? 1 : dist[i - w] + 1;
        if (up < best) best = up;
        if (best < dist[i]) dist[i] = best;
      }
    }
    var bestCell = -1, bestDist = 0;
    var bestPull = double.infinity;
    for (var y = h - 1; y >= 0; y--) {
      for (var x = w - 1; x >= 0; x--) {
        final i = y * w + x;
        if (dist[i] == 0) continue;
        var best = x == w - 1 ? 1 : dist[i + 1] + 1;
        final down = y == h - 1 ? 1 : dist[i + w] + 1;
        if (down < best) best = down;
        if (best < dist[i]) dist[i] = best;

        final dx = x - mx, dy = y - my;
        final pull = dx * dx + dy * dy;
        if (dist[i] > bestDist || (dist[i] == bestDist && pull < bestPull)) {
          bestDist = dist[i];
          bestPull = pull;
          bestCell = i;
        }
      }
    }
    if (bestCell < 0 || bestDist < minThickness) return null;

    // Sig'adigan doira diametri: masofa katakda o'lchangani uchun
    // 2*d - 1 katak. Keyin bir oz kichraytiriladi, chegaraga tegmasin.
    final cells = (2 * bestDist - 1).clamp(0, maxAvatarCells).toDouble();
    return AvatarSlot(
      Offset(
        (bestCell % w + x0 + 0.5) * cellSize,
        (bestCell ~/ w + y0 + 0.5) * cellSize,
      ),
      cells * cellSize * avatarFit,
    );
  }

  static const int _far = 1 << 20;

  /// Avatar chiqishi uchun kerakli eng kichik hudud (katak).
  static const int minCellsForAvatar = 12;

  /// Hudud shuncha katak qalin bo'lmasa avatar chizilmaydi.
  static const int minThickness = 2;

  /// Avatar o'lchamining chegarasi (katak).
  static const int maxAvatarCells = 12;

  /// Sig'adigan doiradan qancha ulush olinadi — chetiga tegib turmasin.
  static const double avatarFit = 0.75;

  /// Hudud chegarasidan silliq `Path` yasaydi (testlar ham shuni chaqiradi).
  static Path buildPath(
    GameGrid grid,
    int playerId,
    (int, int, int, int) b,
    double cellSize,
  ) {
    final owner = grid.owner;
    final w = grid.width;
    bool inside(int x, int y) {
      if (x < 0 || y < 0 || x >= w || y >= grid.height) return false;
      return owner[y * w + x] == playerId;
    }

    final loops = ContourBuilder.trace(inside, b.$1, b.$2, b.$3, b.$4);
    final path = Path()..fillType = PathFillType.nonZero;
    for (final raw in loops) {
      final pts = ContourBuilder.smooth(
        ContourBuilder.simplify(
          ContourBuilder.dropCollinear(raw),
          simplifyTolerance,
        ),
        iterations: smoothPasses,
      );
      if (pts.length < 3) continue;
      path.moveTo(pts[0].dx * cellSize, pts[0].dy * cellSize);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx * cellSize, pts[i].dy * cellSize);
      }
      path.close();
    }
    return path;
  }

  void dispose() {
    for (final c in _cache.values) {
      c.picture.dispose();
    }
    _cache.clear();
    _avatars.dispose();
  }
}

class _Cached {
  _Cached(this.version, this.picture, this.slot);

  final int version;
  final ui.Picture picture;
  final AvatarSlot? slot;
}

/// Avatar naqshining joylashuvi.
class PatternLayout {
  const PatternLayout(this.step, this.cols, this.rows);

  /// Belgilar orasidagi masofa (dunyo birligida).
  final double step;
  final int cols;
  final int rows;

  int get tiles => cols * rows;
}

/// Hudud ichida avatar chiziladigan joy (dunyo koordinatalarida).
class AvatarSlot {
  const AvatarSlot(this.center, this.size);

  final Offset center;
  final double size;
}

/// Izni haqiqiy yo'l bo'ylab silliq lenta qilib chizadi.
class TrailPainter {
  TrailPainter(this.cellSize);

  final double cellSize;

  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  void paint(ui.Canvas canvas, PlayerState p) {
    final pts = p.trailPath;
    if (pts.length < 2) return;

    final path = Path()..moveTo(pts[0] * cellSize, pts[1] * cellSize);
    for (var i = 2; i < pts.length; i += 2) {
      path.lineTo(pts[i] * cellSize, pts[i + 1] * cellSize);
    }
    // Yo'lning oxirini o'yinchining hozirgi joyiga ulaymiz, aks holda
    // lenta boshdan bir oz orqada qolib ko'rinadi.
    path.lineTo(p.x * cellSize, p.y * cellSize);

    final depth = cellSize * Palette.depthFactor;
    final width = cellSize * 1.15;

    // Iz ham hudud kabi qalinlikka ega: pastga surilgan to'q nusxa.
    _stroke
      ..color = Palette.side(p.colorIndex)
      ..strokeWidth = width;
    canvas.drawPath(path.shift(Offset(0, depth)), _stroke);

    _stroke
      ..color = Palette.trail(p.colorIndex)
      ..strokeWidth = width;
    canvas.drawPath(path, _stroke);
  }
}
