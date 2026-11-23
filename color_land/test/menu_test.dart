import 'package:color_land/i18n/app_language.dart';
import 'package:color_land/i18n/l10n.dart';
import 'package:color_land/storage/settings_store.dart';
import 'package:color_land/ui/menu_screen.dart';
import 'package:color_land/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_helpers.dart';

Future<SettingsStore> storeWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SettingsStore.load();
}

Future<void> pumpMenu(WidgetTester tester, SettingsStore store) async {
  await tester.pumpWidget(
    L10n(
      controller: LanguageController(store, AppLanguage.uz),
      child: MaterialApp(home: MenuScreen(store: store)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('beletlar soni raqam bilan ko\'rinadi', (tester) async {
    final store = await storeWith(<String, Object>{'tickets': 4});
    await pumpMenu(tester, store);
    expect(find.text('4'), findsOneWidget);
    expect(find.text(r'$count'), findsNothing);
  });

  testWidgets('profil kartasida taxallus ko\'rinadi', (tester) async {
    final store = await storeWith(<String, Object>{
      'nickname': 'Alisher',
      'avatar': 'flag:UZ',
    });
    await pumpMenu(tester, store);
    expect(find.text('Alisher'), findsOneWidget);
  });

  testWidgets('taxallus kiritilmagan bo\'lsa standart nom turadi', (
    tester,
  ) async {
    final store = await storeWith(<String, Object>{});
    await pumpMenu(tester, store);
    expect(find.text('Siz'), findsOneWidget);
  });

  testWidgets('profil kartasi bosilsa profil ekrani ochiladi', (tester) async {
    final store = await storeWith(<String, Object>{'nickname': 'Alisher'});
    await pumpMenu(tester, store);

    await tester.tap(find.text('Alisher'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('profilda yangi taxallus saqlanadi', (tester) async {
    final store = await storeWith(<String, Object>{});
    await pumpMenu(tester, store);
    await tester.tap(find.text('Siz'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '  Alisher  ');
    await tester.tap(findButton('Saqlash'));
    await tester.pumpAndSettle();

    // Probellar olinadi va menyuga qaytiladi.
    expect(store.nickname, 'Alisher');
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.text('Alisher'), findsOneWidget);
  });

  testWidgets('bo\'sh taxallus saqlansa standart nom qoladi', (tester) async {
    final store = await storeWith(<String, Object>{'nickname': 'Alisher'});
    await pumpMenu(tester, store);
    await tester.tap(find.text('Alisher'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.tap(findButton('Saqlash'));
    await tester.pumpAndSettle();

    expect(store.nickname, 'Siz');
  });
}
