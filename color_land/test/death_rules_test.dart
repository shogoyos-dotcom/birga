import 'dart:math' as math;

import 'package:color_land/game/logic/game_events.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const double kEast = 0.0;
const double kWest = math.pi;
const double kSouth = math.pi / 2;
const double kNorth = -math.pi / 2;

void main() {
  group("o'lim qoidalari", () {
    test('xarita chegarasiga urilsa o\'ladi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);

      walk(world, p, kNorth, 14);

      expect(p.alive, isFalse);
      expect(p.deathCause, DeathCause.wall);
    });

    test('o\'z izini kesib o\'tsa o\'ladi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);

      walk(world, p, kEast, 6); // iz: y=10, x=13..16
      walk(world, p, kSouth, 2); // iz: x=16, y=11..12
      walk(world, p, kWest, 3); // iz: y=12, x=15..13
      walk(world, p, kNorth, 2); // (13,11) -> (13,10) = o'z izi

      expect(p.alive, isFalse);
      expect(p.deathCause, DeathCause.selfCross);
    });

    test('raqib izga tegsa — izning egasi o\'ladi, tegganga +1 kill', () {
      final world = makeWorld();
      final victim = placePlayer(world, left: 4, top: 4, name: 'A');
      final hunter = placePlayer(
        world,
        left: 14,
        top: 14,
        name: 'B',
        colorIndex: 1,
      );
      hunter.speed = 0; // B kutib turadi

      walk(world, victim, kEast, 6); // A ning izi: y=6, x=9..12
      expect(world.grid.trailAt(10, 6), victim.id);

      victim.speed = 0;
      hunter.speed = 8;
      hunter.placeAt(10.5, 4.5, kSouth);

      walk(world, hunter, kSouth, 2); // (10,5) -> (10,6) = A ning izi

      expect(victim.alive, isFalse);
      expect(victim.deathCause, DeathCause.trailHit);
      expect(hunter.kills, 1);
      expect(hunter.alive, isTrue);
      final death = world.events.whereType<DeathEvent>().last;
      expect(death.playerId, victim.id);
      expect(death.killerId, hunter.id);
    });

    test('endigina qo\'yilgan izga qaytib kirish o\'ldirmaydi', () {
      // Barmoq tebranganda o'yinchi hozirgina chiqqan katagiga qaytib
      // kirib qolishi mumkin — bu qoida buzilishi emas.
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);

      // Hududdan uzoqroq chiqamiz, shunda ortga qadam hududga qaytmaydi.
      walk(world, p, kEast, 5);
      expect(p.trail.length, 3, reason: '13, 14 va 15-kataklar');
      final cellsBefore = p.trail.length;

      walk(world, p, kWest, 1); // endigina qo'ygan iziga qaytadi
      expect(p.alive, isTrue, reason: 'ortga bir katak — o\'lim emas');

      walk(world, p, kEast, 1);
      expect(p.alive, isTrue);
      expect(p.trail.length, cellsBefore, reason: 'iz takrorlanmaydi');
    });

    test('eski izga tegish baribir o\'ldiradi', () {
      // Grace oynasi faqat eng so'nggi bir necha katakka tegishli:
      // uzoqroqdagi izni kesib o'tish hamon o'lim.
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);

      walk(world, p, kEast, 6);
      walk(world, p, kSouth, 2);
      walk(world, p, kWest, 3);
      walk(world, p, kNorth, 2); // boshlang\'ich izni kesadi

      expect(p.alive, isFalse);
      expect(p.deathCause, DeathCause.selfCross);
    });

    test('o\'z hududim ichidagi raqib izini kessam ham o\'ladi', () {
      // Raqib mening hududim ustidan o'tayotganda ham o'z hududidan
      // tashqarida hisoblanadi, demak iz qoldiradi. O'sha izga tegsam,
      // u o'lishi kerak — iz qayerda yotgani ahamiyatsiz.
      final world = makeWorld();
      final me = placePlayer(world, left: 8, top: 8, name: 'Men');
      final rival = placePlayer(
        world,
        left: 1,
        top: 8,
        name: 'Raqib',
        colorIndex: 1,
      );

      // Raqib mening hududimga kirib, iz qoldiradi.
      me.speed = 0;
      walk(world, rival, kEast, 5);
      expect(
        world.grid.trailAt(8, 10),
        rival.id,
        reason: 'mening katagimda raqibning izi yotibdi',
      );
      expect(world.grid.ownerAt(8, 10), me.id, reason: 'katak baribir meniki');

      // Endi men o'sha izning ustidan o'taman — lekin o'z hududimdan
      // chiqmay. Aks holda izni hududimdan tashqarida kesgan bo'lardim
      // va bu boshqa holat.
      rival.speed = 0;
      me.speed = 8;
      walk(world, me, kWest, 2);

      expect(me.cx, 8, reason: 'izning ustida turibman');
      expect(
        world.grid.ownerAt(me.cx, me.cy),
        me.id,
        reason: 'hali ham o\'z hududim ichidaman',
      );

      expect(rival.alive, isFalse, reason: 'izini kesdim — o\'lishi kerak');
      expect(rival.deathCause, DeathCause.trailHit);
      expect(me.kills, 1);
      expect(me.alive, isTrue);
    });

    test('o\'z iziga tegish raqibni o\'ldirmaydi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);
      walk(world, p, kEast, 4);
      expect(p.alive, isTrue);
      expect(p.kills, 0);
    });

    test('butun hududi egallansa o\'ladi', () {
      final world = makeWorld();
      final victim = placePlayer(world, left: 10, top: 10, name: 'A');
      final taker = world.addPlayer(name: 'B', colorIndex: 1, isBot: false);

      // B ning hududi — A ning 5x5 ini o'rab turgan ramka (9..15).
      final g = world.grid;
      for (var x = 9; x <= 15; x++) {
        g.setOwner(x, 9, taker.id);
        g.setOwner(x, 15, taker.id);
      }
      for (var y = 9; y <= 15; y++) {
        g.setOwner(9, y, taker.id);
        g.setOwner(15, y, taker.id);
      }
      taker.placeAt(9.5, 9.5, kNorth);
      expect(g.territoryOf(victim.id), 25);

      // B kichik tsikl chizib o'z hududiga qaytadi -> flood fill ishga tushadi.
      walk(world, taker, kNorth, 1);
      walk(world, taker, kEast, 1);
      walk(world, taker, kSouth, 1);

      expect(victim.alive, isFalse, reason: dumpOwners(world));
      expect(victim.deathCause, DeathCause.territoryLost);
      expect(taker.kills, 1);
      expect(g.territoryOf(victim.id), 0);
    });

    test('o\'lgan o\'yinchining hududi va izi bo\'sh bo\'ladi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);
      walk(world, p, kEast, 4); // hudud + iz bor
      expect(world.grid.territoryOf(p.id), 25);
      expect(p.trail, isNotEmpty);

      world.kill(p, DeathCause.wall, null);

      expect(world.grid.territoryOf(p.id), 0);
      for (var i = 0; i < world.grid.owner.length; i++) {
        expect(world.grid.owner[i], isNot(p.id));
        expect(world.grid.trail[i], isNot(p.id));
      }
      expect(p.trail, isEmpty);
    });

    test('o\'lgandan keyin ham yakuniy hudud bilinadi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);
      walk(world, p, kEast, 4);
      final before = world.percentOf(p);
      expect(before, greaterThan(0));

      world.kill(p, DeathCause.wall, null);

      expect(world.grid.percentOf(p.id), 0, reason: 'panjara tozalanadi');
      expect(
        world.percentOf(p),
        closeTo(before, 1e-9),
        reason: 'natija oynasi uchun o\'limdagi qiymat saqlanadi',
      );
      expect(p.finalTerritory, 25);
    });

    test('o\'lim hodisasi bo\'shagan kataklarni olib yuradi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);
      world.events.clear();

      world.kill(p, DeathCause.wall, null);

      final death = world.events.whereType<DeathEvent>().single;
      expect(
        death.clearedCells.length,
        25,
        reason: 'animatsiya uchun 5x5 hudud qaytariladi',
      );
      for (final i in death.clearedCells) {
        expect(world.grid.owner[i], 0);
      }
    });

    test('o\'lim ikki marta hisoblanmaydi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);
      final other = placePlayer(world, left: 2, top: 2, colorIndex: 1);
      other.speed = 0;

      world.kill(p, DeathCause.wall, other);
      world.kill(p, DeathCause.wall, other);

      expect(other.kills, 1);
    });
  });

  group('iz va hudud egallash', () {
    test('istalgan burchakda harakatlanadi — 4 tomonga cheklanmagan', () {
      final world = makeWorld(width: 40, height: 40);
      final p = placePlayer(world, left: 17, top: 17);
      final startX = p.x;
      final startY = p.y;

      // 34 daraja — na gorizontal, na vertikal, na aniq diagonal.
      const angle = 0.6;
      walk(world, p, angle, 8);

      expect(p.alive, isTrue);
      expect(
        p.x - startX,
        closeTo(math.cos(angle) * 8, 0.15),
        reason: 'x bo\'yicha siljish burchakka mos',
      );
      expect(
        p.y - startY,
        closeTo(math.sin(angle) * 8, 0.15),
        reason: 'y bo\'yicha siljish burchakka mos',
      );
    });

    test('burilish burchagi saqlanadi, tomonlarga tortilmaydi', () {
      final world = makeWorld(width: 40, height: 40);
      final p = placePlayer(world, left: 17, top: 17);

      // Har xil burchaklar: hech biri 90 darajaga yaxlitlanmasligi kerak.
      for (final angle in <double>[0.3, 1.1, 2.4, -0.9, -2.7]) {
        p.steerTo(angle);
        world.update(1 / 60);
        expect(
          p.angle,
          closeTo(angle, 1e-9),
          reason: '$angle radian saqlanishi kerak',
        );
      }
    });

    test('qiya yurganda iz zinapoya shaklida qoladi', () {
      final world = makeWorld(width: 40, height: 40);
      final p = placePlayer(world, left: 17, top: 17);

      walk(world, p, 0.6, 10);

      final xs = <int>{};
      final ys = <int>{};
      for (final i in p.trail) {
        xs.add(i % world.grid.width);
        ys.add(i ~/ world.grid.width);
      }
      expect(xs.length, greaterThan(1), reason: 'x bo\'yicha ham suriladi');
      expect(ys.length, greaterThan(1), reason: 'y bo\'yicha ham suriladi');
    });

    test('o\'z hududidan chiqqanda iz qoladi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);

      walk(world, p, kEast, 5);

      expect(p.trail, isNotEmpty);
      expect(world.grid.trailAt(13, 10), p.id);
      expect(world.grid.ownerAt(13, 10), 0, reason: 'hali egallanmagan');
    });

    test('hududiga qaytganda iz va o\'ralgan kataklar egallanadi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);
      final before = world.grid.territoryOf(p.id);

      // Hududdan chiqib to'rtburchak chizib qaytadi.
      walk(world, p, kNorth, 4); // y: 10.5 -> 6.5, iz (10,9)..(10,7)
      walk(world, p, kEast, 3); // iz (11,6)..(13,6)
      walk(world, p, kSouth, 5); // iz (13,7)..(13,11)
      walk(world, p, kWest, 2); // (12,11) -> (11,11) o'z hududi

      expect(p.alive, isTrue, reason: dumpOwners(world));
      expect(p.trail, isEmpty, reason: 'qaytgach iz tozalanadi');
      expect(
        world.grid.territoryOf(p.id),
        greaterThan(before),
        reason: dumpOwners(world),
      );
      expect(world.grid.ownerAt(11, 8), p.id, reason: 'o\'ralgan katak');
      expect(
        world.events.whereType<CaptureEvent>(),
        isNotEmpty,
        reason: 'egallash hodisasi chiqadi',
      );
    });

    test('hudud foizi hisoblanadi', () {
      final world = makeWorld(width: 20, height: 20);
      final p = placePlayer(world, left: 5, top: 5);
      expect(world.grid.percentOf(p.id), closeTo(25 * 100 / 400, 1e-9));
    });

    test('reyting hudud bo\'yicha saralanadi', () {
      final world = makeWorld();
      final small = placePlayer(
        world,
        left: 2,
        top: 2,
        size: 3,
        name: 'kichik',
      );
      final big = placePlayer(
        world,
        left: 12,
        top: 12,
        size: 7,
        name: 'katta',
        colorIndex: 1,
      );

      final board = world.leaderboard();
      expect(board.first.id, big.id);
      expect(board.last.id, small.id);
    });
  });
}
