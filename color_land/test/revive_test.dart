import 'package:color_land/game/logic/game_events.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group("o'limdan keyin davom etish", () {
    test('hududi bo\'sh turgan bo\'lsa o\'sha joyida tiklanadi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);
      world.events.clear();
      world.kill(p, DeathCause.selfCross, null);
      final cleared = world.events.whereType<DeathEvent>().single.clearedCells;

      final ok = world.revive(p, cleared);

      expect(ok, isTrue);
      expect(p.alive, isTrue);
      expect(p.deathCause, DeathCause.none);
      expect(world.grid.territoryOf(p.id), 25, reason: 'hudud qaytarildi');
      expect(
        world.grid.ownerAt(p.cx, p.cy),
        p.id,
        reason: "o'z hududining ichida turadi",
      );
      expect(p.trail, isEmpty);
    });

    test("o'ldirishlar soni saqlanadi", () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);
      p.kills = 4;
      world.events.clear();
      world.kill(p, DeathCause.selfCross, null);
      final cleared = world.events.whereType<DeathEvent>().single.clearedCells;

      world.revive(p, cleared);

      expect(p.kills, 4);
    });

    test('hududini boshqa egallab bo\'lsa, yangi joydan boshlanadi', () {
      // Yangi joy topilishi uchun maydon kattaroq bo'lsin.
      final world = makeWorld(width: 40, height: 40);
      final p = placePlayer(world, left: 8, top: 8);
      final rival = placePlayer(world, left: 2, top: 2, colorIndex: 1);
      world.events.clear();
      world.kill(p, DeathCause.selfCross, null);
      final cleared = world.events.whereType<DeathEvent>().single.clearedCells;

      // Bo'shagan hamma katakni raqib egallab oladi.
      for (final i in cleared) {
        world.grid.setOwnerIndex(i, rival.id);
      }

      final ok = world.revive(p, cleared);

      expect(ok, isTrue);
      expect(p.alive, isTrue);
      expect(world.grid.territoryOf(p.id), 21, reason: 'yangi doira');
      for (final i in cleared) {
        expect(
          world.grid.owner[i],
          rival.id,
          reason: "raqibning hududi tortib olinmaydi",
        );
      }
    });

    test('joy qolmasa false qaytaradi', () {
      // Butun maydon raqibniki — na tiklash, na yangi joy mumkin.
      final world = makeWorld(width: 20, height: 20);
      final p = placePlayer(world, left: 7, top: 7);
      final rival = placePlayer(world, left: 1, top: 1, colorIndex: 1);
      world.events.clear();
      world.kill(p, DeathCause.selfCross, null);
      final cleared = world.events.whereType<DeathEvent>().single.clearedCells;
      for (var i = 0; i < world.grid.owner.length; i++) {
        world.grid.setOwnerIndex(i, rival.id);
      }

      expect(world.revive(p, cleared), isFalse);
      expect(p.alive, isFalse);
    });

    test('tirik o\'yinchiga ta\'sir qilmaydi', () {
      final world = makeWorld();
      final p = placePlayer(world, left: 8, top: 8);
      final before = world.grid.territoryOf(p.id);

      expect(world.revive(p, const []), isTrue);

      expect(p.alive, isTrue);
      expect(world.grid.territoryOf(p.id), before);
    });
  });
}
