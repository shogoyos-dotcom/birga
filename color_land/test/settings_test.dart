import 'package:color_land/game/logic/difficulty.dart';
import 'package:color_land/game/render/game_theme.dart';
import 'package:color_land/game/render/palette.dart';
import 'package:color_land/i18n/app_language.dart';
import 'package:color_land/i18n/l10n.dart';
import 'package:color_land/services/audio_service.dart';
import 'package:color_land/storage/settings_store.dart';
import 'package:color_land/ui/menu_screen.dart';
import 'package:color_land/ui/settings_screen.dart';
import 'package:color_land/ui/theme/arcade.dart';
import 'package:color_land/ui/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsStore> storeWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SettingsStore.load();
}

AudioService silentAudio() => AudioService(
  musicEnabled: false,
  soundEnabled: false,
  vibrationEnabled: false,
);

Future<void> pumpSettings(
  WidgetTester tester,
  SettingsStore store, {
  AudioService? audio,
}) async {
  await tester.pumpWidget(
    L10n(
      controller: LanguageController(store, AppLanguage.uz),
      child: MaterialApp(
        theme: Arcade.themeData(),
        home: SettingsScreen(store: store, audio: audio ?? silentAudio()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Sozlamalar ro'yxati uzun — tegishli qator ko'rinmasa, tap() ni
/// o'tkazib yuboradi. Shuning uchun avval ekranga keltiramiz.
Future<void> tapRow(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AudioService.disabled = true);
  tearDown(() => AudioService.disabled = false);

  group('sozlamalar ekrani', () {
    testWidgets('rang tanlansa saqlanadi', (tester) async {
      final store = await storeWith(<String, Object>{});
      await pumpSettings(tester, store);

      await tester.ensureVisible(find.byType(ColorChip).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ColorChip).at(2));
      await tester.pumpAndSettle();
      expect(store.colorIndex, 2);
    });

    testWidgets('uslub tanlansa saqlanadi va darhol qo\'llanadi', (
      tester,
    ) async {
      final store = await storeWith(<String, Object>{});
      addTearDown(() => Palette.theme = GameTheme.fallback);
      await pumpSettings(tester, store);

      await tapRow(tester, 'Neon');
      expect(store.theme.id, 'neon');
      expect(Palette.theme.id, 'neon', reason: 'arena darhol o\'zgarsin');
    });

    testWidgets('qiyinlik tanlansa saqlanadi', (tester) async {
      final store = await storeWith(<String, Object>{});
      await pumpSettings(tester, store);

      await tapRow(tester, 'Qiyin');
      expect(store.difficulty, Difficulty.hard);
    });

    testWidgets('til tanlansa interfeys o\'zgaradi', (tester) async {
      final store = await storeWith(<String, Object>{});
      await pumpSettings(tester, store);
      expect(find.text('Musiqa'), findsOneWidget);

      await tapRow(tester, 'English');
      expect(store.language, AppLanguage.en);
    });

    testWidgets('musiqa, ovoz va vibratsiya alohida saqlanadi', (tester) async {
      final store = await storeWith(<String, Object>{});
      final audio = silentAudio()
        ..musicEnabled = true
        ..soundEnabled = true
        ..vibrationEnabled = true;
      await pumpSettings(tester, store, audio: audio);

      // Standart holat — uchalasi yoqilgan.
      expect(store.musicEnabled, isTrue);
      expect(store.soundEnabled, isTrue);
      expect(store.vibrationEnabled, isTrue);

      await tapRow(tester, 'Musiqa');
      expect(store.musicEnabled, isFalse);
      expect(
        audio.musicEnabled,
        isFalse,
        reason: 'xizmat ham xabardor bo\'lsin',
      );
      expect(store.soundEnabled, isTrue, reason: 'boshqalariga tegmasin');

      await tapRow(tester, 'Vibratsiya');
      expect(store.vibrationEnabled, isFalse);
      expect(audio.vibrationEnabled, isFalse);
      expect(store.musicEnabled, isFalse);
      expect(store.soundEnabled, isTrue);
    });

    testWidgets('saqlangan qiymatlar ochilganda ko\'rsatiladi', (tester) async {
      final store = await storeWith(<String, Object>{
        'music': false,
        'sound': true,
        'vibration': false,
      });
      await pumpSettings(tester, store);

      await tester.ensureVisible(find.text('Vibratsiya'));
      await tester.pumpAndSettle();
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.map((s) => s.value), <bool>[false, true, false]);
    });
  });

  group('bosh menyu', () {
    Future<void> pumpMenu(WidgetTester tester, SettingsStore store) async {
      await tester.pumpWidget(
        L10n(
          controller: LanguageController(store, AppLanguage.uz),
          child: MaterialApp(
            theme: Arcade.themeData(),
            home: MenuScreen(store: store, audio: silentAudio()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tanlovlar menyuda qolmagan', (tester) async {
      final store = await storeWith(<String, Object>{});
      await pumpMenu(tester, store);

      expect(find.text('RANG TANLANG'), findsNothing);
      expect(find.text('USLUB'), findsNothing);
      expect(find.text('QIYINLIK'), findsNothing);
      expect(find.text("O'zbekcha"), findsNothing);
    });

    testWidgets('sozlamalar tugmasi sozlamalar ekranini ochadi', (
      tester,
    ) async {
      final store = await storeWith(<String, Object>{});
      await pumpMenu(tester, store);

      await tester.tap(find.byTooltip('Sozlamalar'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('sozlamada tanlangan qiyinlik o\'yinga uzatiladi', (
      tester,
    ) async {
      final store = await storeWith(<String, Object>{'difficulty': 'hard'});
      await pumpMenu(tester, store);
      expect(store.difficulty, Difficulty.hard);
    });
  });

  group('vibratsiya', () {
    List<MethodCall> hooked(WidgetTester tester) {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method.startsWith('HapticFeedback')) calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return calls;
    }

    testWidgets('yoqilganda qurilma titraydi', (tester) async {
      AudioService.disabled = false;
      final calls = hooked(tester);
      // Ovoz o'chirilgan — test muhitida audio qurilmasi yo'q.
      AudioService(
        musicEnabled: false,
        soundEnabled: false,
        vibrationEnabled: true,
      ).kill();
      await tester.pump();
      expect(calls, hasLength(1));
    });

    testWidgets('o\'chirilganda titramaydi', (tester) async {
      AudioService.disabled = false;
      final calls = hooked(tester);
      AudioService(
        musicEnabled: false,
        soundEnabled: false,
        vibrationEnabled: false,
      ).kill();
      await tester.pump();
      expect(calls, isEmpty);
    });
  });
}
