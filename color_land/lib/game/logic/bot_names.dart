import 'dart:math' as math;

/// Botlar uchun qisqa, tilga bog'liq bo'lmagan nomlar.
const List<String> kBotNames = <String>[
  'Niko',
  'Zara',
  'Max',
  'Lola',
  'Rico',
  'Mira',
  'Taho',
  'Juno',
  'Kira',
  'Omar',
  'Vega',
  'Pixi',
  'Dino',
  'Sora',
  'Luka',
  'Nova',
  'Bodo',
  'Elsa',
  'Ravi',
  'Tara',
  'Milo',
  'Yuki',
  'Gizo',
  'Alma',
];

/// Takrorlanmaydigan `count` ta nom tanlaydi.
List<String> pickBotNames(int count, math.Random rng) {
  final pool = List<String>.of(kBotNames)..shuffle(rng);
  if (count <= pool.length) return pool.sublist(0, count);
  return List<String>.generate(count, (i) => pool[i % pool.length]);
}
