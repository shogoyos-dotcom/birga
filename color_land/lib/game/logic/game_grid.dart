import 'dart:typed_data';

/// Mantiqiy panjara. Har bir katakda egasi (`owner`) va iz egasi (`trail`)
/// saqlanadi; 0 — bo'sh, aks holda o'yinchi ID (1..255).
///
/// Rendering uchun o'zgargan "chunk"lar ro'yxati yuritiladi — shunda ekran
/// har kadrda butunlay qayta chizilmaydi.
class GameGrid {
  GameGrid(int width, int height, {int chunkCells = 16})
    : width = width,
      height = height,
      chunkCells = chunkCells,
      chunksX = (width + chunkCells - 1) ~/ chunkCells,
      chunksY = (height + chunkCells - 1) ~/ chunkCells,
      owner = Uint8List(width * height),
      trail = Uint8List(width * height),
      _territory = Int32List(256),
      _version = Int32List(256),
      _minX = Int32List(256),
      _minY = Int32List(256),
      _maxX = Int32List(256),
      _maxY = Int32List(256) {
    _territory[0] = width * height;
    _resetBounds();
  }

  void _resetBounds() {
    _minX.fillRange(0, 256, 1 << 30);
    _minY.fillRange(0, 256, 1 << 30);
    _maxX.fillRange(0, 256, -1);
    _maxY.fillRange(0, 256, -1);
  }

  final int width;
  final int height;

  /// Bir chunk tomoni (katak hisobida).
  final int chunkCells;
  final int chunksX;
  final int chunksY;

  /// Katak egasi: 0 — bo'sh, aks holda o'yinchi ID.
  final Uint8List owner;

  /// Katakdagi iz egasi: 0 — iz yo'q, aks holda o'yinchi ID.
  final Uint8List trail;

  final Int32List _territory;

  // Har bir o'yinchi hududini o'z ichiga oluvchi to'rtburchak. Hudud
  // kengayganda yangilanadi, qisqarganda esa qisqarmaydi — kattaroq
  // to'rtburchak ham to'g'ri natija beradi, shunchaki biroz ko'proq
  // katak tekshiriladi.
  /// Har bir o'yinchi hududi o'zgarganda oshadi — chizish keshi shu
  /// orqali qachon eskirganini biladi.
  final Int32List _version;

  final Int32List _minX;
  final Int32List _minY;
  final Int32List _maxX;
  final Int32List _maxY;

  /// Oxirgi tozalashdan beri o'zgargan chunklar.
  final Set<int> dirtyChunks = <int>{};

  int get cellCount => width * height;

  int index(int x, int y) => y * width + x;

  bool contains(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  int ownerAt(int x, int y) => owner[y * width + x];

  int trailAt(int x, int y) => trail[y * width + x];

  /// `id` egallagan kataklar soni.
  int territoryOf(int id) => _territory[id];

  /// `id` egallagan maydon foizi (0..100).
  double percentOf(int id) => _territory[id] * 100.0 / cellCount;

  void markDirtyIndex(int i) {
    final x = i % width;
    final y = i ~/ width;
    dirtyChunks.add((y ~/ chunkCells) * chunksX + (x ~/ chunkCells));
  }

  void markAllDirty() {
    for (var i = 0; i < chunksX * chunksY; i++) {
      dirtyChunks.add(i);
    }
  }

  void setOwnerIndex(int i, int id) {
    final prev = owner[i];
    if (prev == id) return;
    _territory[prev]--;
    _territory[id]++;
    owner[i] = id;
    _version[prev]++;
    _version[id]++;
    if (id != 0) {
      final x = i % width;
      final y = i ~/ width;
      if (x < _minX[id]) _minX[id] = x;
      if (y < _minY[id]) _minY[id] = y;
      if (x > _maxX[id]) _maxX[id] = x;
      if (y > _maxY[id]) _maxY[id] = y;
    }
    markDirtyIndex(i);
  }

  /// `id` hududi necha marta o'zgargani. Faqat solishtirish uchun.
  int versionOf(int id) => _version[id];

  /// `id` ning butun hududini o'rab turgan to'rtburchak:
  /// `(minX, minY, maxX, maxY)`. Hudud bo'sh bo'lsa `null`.
  ///
  /// Hudud qisqarganda to'rtburchak kichraymaydi — bu xavfsiz, chunki
  /// kattaroq soha ham to'g'ri javob beradi.
  (int, int, int, int)? boundsOf(int id) {
    if (_maxX[id] < 0) return null;
    return (_minX[id], _minY[id], _maxX[id], _maxY[id]);
  }

  void setOwner(int x, int y, int id) => setOwnerIndex(index(x, y), id);

  void setTrailIndex(int i, int id) {
    if (trail[i] == id) return;
    trail[i] = id;
    markDirtyIndex(i);
  }

  void setTrail(int x, int y, int id) => setTrailIndex(index(x, y), id);

  /// `id` ning butun hududi va izini bo'sh qiladi (o'lim paytida).
  /// Bo'shatilgan hudud kataklarini qaytaradi — o'lim animatsiyasi uchun.
  List<int> clearPlayer(int id) {
    final cleared = <int>[];
    if (id == 0) return cleared;
    for (var i = 0; i < owner.length; i++) {
      if (owner[i] == id) {
        _territory[id]--;
        _territory[0]++;
        owner[i] = 0;
        _version[id]++;
        _version[0]++;
        markDirtyIndex(i);
        cleared.add(i);
      }
      if (trail[i] == id) {
        trail[i] = 0;
        markDirtyIndex(i);
      }
    }
    _minX[id] = 1 << 30;
    _minY[id] = 1 << 30;
    _maxX[id] = -1;
    _maxY[id] = -1;
    return cleared;
  }

  /// `id` ning izini tozalaydi, hududiga tegmaydi.
  void clearTrailOf(int id) {
    if (id == 0) return;
    for (var i = 0; i < trail.length; i++) {
      if (trail[i] == id) {
        trail[i] = 0;
        markDirtyIndex(i);
      }
    }
  }

  /// Markazi `(cx, cy)` bo'lgan doirani `id` ga beradi va katak sonini
  /// qaytaradi. Boshlang'ich hudud kvadrat emas, doira bo'lsin uchun.
  int fillDisc(int cx, int cy, double radius, int id) {
    final r2 = radius * radius;
    final from = (radius).ceil();
    var count = 0;
    for (var dy = -from; dy <= from; dy++) {
      for (var dx = -from; dx <= from; dx++) {
        // Katak markazigacha bo'lgan masofa bilan solishtiramiz.
        if (dx * dx + dy * dy > r2) continue;
        final x = cx + dx;
        final y = cy + dy;
        if (!contains(x, y)) continue;
        setOwner(x, y, id);
        count++;
      }
    }
    return count;
  }

  /// `left,top` dan boshlab `size x size` kvadratni `id` ga beradi.
  void fillBlock(int left, int top, int size, int id) {
    for (var y = top; y < top + size; y++) {
      for (var x = left; x < left + size; x++) {
        if (contains(x, y)) setOwner(x, y, id);
      }
    }
  }

  /// `left,top` dan boshlangan kvadrat butunlay bo'sh (egasiz va izsiz) bo'lsa — true.
  bool isBlockFree(int left, int top, int size) {
    for (var y = top; y < top + size; y++) {
      for (var x = left; x < left + size; x++) {
        if (!contains(x, y)) return false;
        final i = index(x, y);
        if (owner[i] != 0 || trail[i] != 0) return false;
      }
    }
    return true;
  }

  void reset() {
    owner.fillRange(0, owner.length, 0);
    trail.fillRange(0, trail.length, 0);
    _territory.fillRange(0, _territory.length, 0);
    _territory[0] = cellCount;
    _resetBounds();
    markAllDirty();
  }
}
