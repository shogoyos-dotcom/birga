import 'package:color_land/game/logic/game_config.dart';
import 'package:color_land/i18n/app_language.dart';
import 'package:color_land/i18n/l10n.dart';
import 'package:color_land/services/continue_services.dart';
import 'package:color_land/storage/settings_store.dart';
import 'package:color_land/ui/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_helpers.dart';

/// Reklama ko'rsatishni nazorat qilish uchun.
class FakeAds implements RewardedAdService {
  FakeAds({this.ready = true, this.watched = true});

  bool ready;
  bool watched;
  int shownCount = 0;

  @override
  bool get isReady => ready;

  @override
  Future<void> preload() async {}

  @override
  Future<bool> showRewarded() async {
    shownCount++;
    return watched;
  }
}

Future<GameScreenState> startGame(
  WidgetTester tester,
  SettingsStore store, {
  RewardedAdService? ads,
}) async {
  await tester.pumpWidget(
    L10n(
      controller: LanguageController(store, AppLanguage.uz),
      child: MaterialApp(
        home: GameScreen(
          config: const GameConfig(gridWidth: 64, gridHeight: 64, botCount: 0),
          colorIndex: 0,
          store: store,
          ads: ads,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<GameScreenState>(find.byType(GameScreen));
}

Future<void> die(WidgetTester tester, GameScreenState screen) =>
    dieBySelfCross(tester, screen.gameForTest);

void main() {
  testWidgets('belet bilan davom etish beletni sarflaydi va tiriltiradi', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'tickets': 2});
    final store = await SettingsStore.load();
    final screen = await startGame(tester, store);

    await die(tester, screen);
    expect(screen.gameForTest.sim.human.alive, isFalse);
    expect(find.text("O'yin tugadi"), findsOneWidget);

    await tester.tap(find.textContaining('Belet bilan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(screen.gameForTest.sim.human.alive, isTrue, reason: 'tirildi');
    expect(store.tickets, 1, reason: 'bitta belet sarflandi');
    expect(find.text("O'yin tugadi"), findsNothing);
  });

  testWidgets('belet qolmasa do\'kon ochiladi', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'tickets': 0});
    final store = await SettingsStore.load();
    final screen = await startGame(tester, store);

    await die(tester, screen);
    // Belet yo'q — tugma "Belet sotib olish" bo'lib turadi.
    await tester.tap(find.text('Belet sotib olish'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text("Do'kon"), findsOneWidget);
    expect(
      screen.gameForTest.sim.human.alive,
      isFalse,
      reason: 'hali tirilmadi',
    );
  });

  testWidgets('reklama ko\'rilsa tiriltiradi, belet sarflanmaydi', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'tickets': 2});
    final store = await SettingsStore.load();
    final ads = FakeAds();
    final screen = await startGame(tester, store, ads: ads);

    await die(tester, screen);
    await tester.tap(find.text("Reklama ko'rish"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(ads.shownCount, 1);
    expect(screen.gameForTest.sim.human.alive, isTrue);
    expect(store.tickets, 2, reason: 'reklama belet sarflamaydi');
  });

  testWidgets('reklama to\'liq ko\'rilmasa tiriltirmaydi', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'tickets': 0});
    final store = await SettingsStore.load();
    final ads = FakeAds(watched: false);
    final screen = await startGame(tester, store, ads: ads);

    await die(tester, screen);
    await tester.tap(find.text("Reklama ko'rish"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(ads.shownCount, 1);
    expect(screen.gameForTest.sim.human.alive, isFalse);
    expect(find.text("O'yin tugadi"), findsOneWidget);
  });

  testWidgets('reklama tayyor bo\'lmasa xabar chiqadi', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'tickets': 0});
    final store = await SettingsStore.load();
    final ads = FakeAds(ready: false);
    final screen = await startGame(tester, store, ads: ads);

    await die(tester, screen);
    await tester.tap(find.text("Reklama ko'rish"));
    await tester.pump();

    expect(ads.shownCount, 0);
    expect(find.text('Reklama hali tayyor emas'), findsOneWidget);
    expect(screen.gameForTest.sim.human.alive, isFalse);
  });
}
