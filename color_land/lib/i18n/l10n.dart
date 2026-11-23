import 'package:flutter/widgets.dart';

import '../storage/settings_store.dart';
import 'app_language.dart';
import 'app_strings.dart';

/// Joriy tilni saqlaydi va o'zgarganda butun interfeysni qayta quradi.
class LanguageController extends ChangeNotifier {
  LanguageController(this._store, AppLanguage initial) : _language = initial;

  final SettingsStore _store;
  AppLanguage _language;

  AppLanguage get language => _language;

  AppStrings get strings => AppStrings.of(_language);

  Future<void> setLanguage(AppLanguage value) async {
    if (value == _language) return;
    _language = value;
    notifyListeners();
    await _store.setLanguage(value);
  }
}

/// Daraxt bo'ylab tilni uzatadi: `L10n.of(context)`.
class L10n extends InheritedNotifier<LanguageController> {
  const L10n({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController controllerOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<L10n>();
    assert(widget != null, 'L10n daraxtda topilmadi');
    return widget!.notifier!;
  }

  static AppStrings of(BuildContext context) => controllerOf(context).strings;
}
