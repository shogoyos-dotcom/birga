import 'dart:ui' show Offset;

/// Kataklar to'plamidan silliq chegara chizig'ini yasaydi.
///
/// Ikki bosqich:
///  1. **Kontur topish.** Har bir "ichki" katakning tashqariga qaragan
///     tomoni chegara bo'lagi hisoblanadi. Bo'laklar uchlari bo'yicha
///     bir-biriga ulanib, yopiq halqalarga aylantiriladi. Teshiklar
///     (ichkaridagi begona sohalar) teskari yo'nalishda chiqadi, shuning
///     uchun `nonZero` to'ldirishda o'zidan o'zi kesib tashlanadi.
///  2. **Silliqlash.** Chaikin usuli: har bir tomon 1/4 va 3/4
///     nuqtalariga almashtiriladi. Ikki marta qo'llansa, burchakli
///     siniq chiziq egri chiziqqa aylanadi.
class ContourBuilder {
  /// `inside(x, y)` — katak shaklga kiradimi.
  /// Soha: `x0..x1`, `y0..y1` (ikkala chekka ham kiradi).
  static List<List<Offset>> trace(
    bool Function(int x, int y) inside,
    int x0,
    int y0,
    int x1,
    int y1,
  ) {
    // Boshlang'ich nuqtasi bo'yicha chegara bo'laklari.
    final starts = <int, List<int>>{};
    // Nuqtani bitta songa aylantiramiz: kenglik chekkalarni ham sig'dirsin.
    final stride = (x1 - x0) + 3;
    int key(int px, int py) => (py - y0) * stride + (px - x0);

    void edge(int ax, int ay, int bx, int by) {
      starts.putIfAbsent(key(ax, ay), () => <int>[]).add(key(bx, by));
    }

    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        if (!inside(x, y)) continue;
        // Yo'nalish shunday tanlanganki, ichkari doim chap tomonda qoladi.
        if (!inside(x, y - 1)) edge(x, y, x + 1, y);
        if (!inside(x + 1, y)) edge(x + 1, y, x + 1, y + 1);
        if (!inside(x, y + 1)) edge(x + 1, y + 1, x, y + 1);
        if (!inside(x - 1, y)) edge(x, y + 1, x, y);
      }
    }

    final loops = <List<Offset>>[];
    while (starts.isNotEmpty) {
      final first = starts.keys.first;
      var current = first;
      final loop = <Offset>[];
      var guard = 0;
      while (guard++ < 1 << 22) {
        final next = starts[current];
        if (next == null || next.isEmpty) break;
        final to = next.removeLast();
        if (next.isEmpty) starts.remove(current);
        loop.add(
          Offset(
            (current % stride + x0).toDouble(),
            (current ~/ stride + y0).toDouble(),
          ),
        );
        current = to;
        if (current == first) break;
      }
      if (loop.length >= 4) loops.add(loop);
    }
    return loops;
  }

  /// Ketma-ket bir chiziqdagi nuqtalarni olib tashlaydi — silliqlash
  /// faqat haqiqiy burchaklarga ta'sir qilsin.
  static List<Offset> dropCollinear(List<Offset> loop) {
    if (loop.length < 3) return loop;
    final out = <Offset>[];
    for (var i = 0; i < loop.length; i++) {
      final prev = loop[(i - 1 + loop.length) % loop.length];
      final cur = loop[i];
      final next = loop[(i + 1) % loop.length];
      final cross =
          (cur.dx - prev.dx) * (next.dy - cur.dy) -
          (cur.dy - prev.dy) * (next.dx - cur.dx);
      if (cross != 0) out.add(cur);
    }
    return out.length >= 3 ? out : loop;
  }

  /// Ramer-Douglas-Peucker soddalashtirishi: berilgan chetlanishdan
  /// kichik egilishlarni olib tashlaydi.
  ///
  /// Buning kerakligi: qiya chegara panjarada bir kataklik pog'onalar
  /// ko'rinishida yotadi. Ularni soddalashtirmasdan silliqlasak, chekka
  /// to'lqinli bo'lib qoladi; soddalashtirgandan keyin esa pog'onalar
  /// bitta to'g'ri qiya chiziqqa aylanadi.
  static List<Offset> simplify(List<Offset> loop, double tolerance) {
    if (loop.length < 4) return loop;

    // Chegarani shakl o'lchamiga bog'laymiz. Busiz kichik hudud (masalan
    // bir necha katak) butunlay yassilanib, ko'rinmay qolardi.
    var minX = loop.first.dx;
    var maxX = loop.first.dx;
    var minY = loop.first.dy;
    var maxY = loop.first.dy;
    for (final p in loop) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    final extent = (maxX - minX) < (maxY - minY)
        ? (maxX - minX)
        : (maxY - minY);
    final limit = tolerance < extent * 0.25 ? tolerance : extent * 0.25;
    if (limit <= 0) return loop;
    tolerance = limit;
    // Yopiq halqani ochiq chiziqqa aylantiramiz: eng uzoq ikki nuqtani
    // tayanch qilib olamiz, shunda shakl buzilmaydi.
    var anchor = 0;
    var farthest = 0;
    var best = -1.0;
    for (var i = 1; i < loop.length; i++) {
      final d = (loop[i] - loop[0]).distanceSquared;
      if (d > best) {
        best = d;
        farthest = i;
      }
    }
    anchor = 0;

    final first = loop.sublist(anchor, farthest + 1);
    final second = <Offset>[...loop.sublist(farthest), loop[anchor]];

    final out = <Offset>[
      ..._rdp(first, tolerance),
      ..._rdp(second, tolerance).skip(1).take(second.length - 2),
    ];
    return out.length >= 3 ? out : loop;
  }

  static List<Offset> _rdp(List<Offset> pts, double tolerance) {
    if (pts.length < 3) return pts;
    final a = pts.first;
    final b = pts.last;
    var maxDist = -1.0;
    var index = 0;
    for (var i = 1; i < pts.length - 1; i++) {
      final d = _perpendicular(pts[i], a, b);
      if (d > maxDist) {
        maxDist = d;
        index = i;
      }
    }
    if (maxDist <= tolerance) return <Offset>[a, b];
    final left = _rdp(pts.sublist(0, index + 1), tolerance);
    final right = _rdp(pts.sublist(index), tolerance);
    return <Offset>[...left.take(left.length - 1), ...right];
  }

  static double _perpendicular(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = dx * dx + dy * dy;
    if (len == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / len).clamp(0.0, 1.0);
    return (p - Offset(a.dx + t * dx, a.dy + t * dy)).distance;
  }

  /// Chaikin silliqlashi. `tension` — burchakni qanchalik kesish (0..0.5).
  static List<Offset> smooth(
    List<Offset> loop, {
    int iterations = 2,
    double tension = 0.25,
  }) {
    var pts = loop;
    for (var it = 0; it < iterations; it++) {
      if (pts.length < 3) return pts;
      final next = <Offset>[];
      for (var i = 0; i < pts.length; i++) {
        final a = pts[i];
        final b = pts[(i + 1) % pts.length];
        next
          ..add(Offset.lerp(a, b, tension)!)
          ..add(Offset.lerp(a, b, 1 - tension)!);
      }
      pts = next;
    }
    return pts;
  }
}
