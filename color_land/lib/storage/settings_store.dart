import 'package:shared_preferences/shared_preferences.dart';

import '../game/logic/difficulty.dart';
import '../game/render/game_theme.dart';
import '../i18n/app_language.dart';

/// O'yinchi sozlamalari va rekordi — `shared_preferences` da saqlanadi.
class SettingsStore {
  SettingsStore._(this._prefs);

  static const _kRecord = 'best_percent';
  static const _kKills = 'best_kills';
  static const _kColor = 'player_color';
  static const _kDifficulty = 'difficulty';
  static const _kLanguage = 'language';
  static const _kTickets = 'tickets';
  static const _kTheme = 'theme';

  /// Ilova birinchi marta ochilganda beriladigan beletlar.
  static const int welcomeTickets = 3;

  final SharedPreferences _prefs;

  static Future<SettingsStore> load() async =>
      SettingsStore._(await SharedPreferences.getInstance());

  /// Eng yaxshi natija — egallangan maydon foizi.
  double get bestPercent => _prefs.getDouble(_kRecord) ?? 0;

  /// Eng ko'p o'ldirishlar soni.
  int get bestKills => _prefs.getInt(_kKills) ?? 0;

  int get colorIndex => _prefs.getInt(_kColor) ?? 0;

  /// Tanlangan vizual uslub.
  GameTheme get theme => GameTheme.byId(_prefs.getString(_kTheme));

  Future<void> setTheme(GameTheme value) => _prefs.setString(_kTheme, value.id);

  /// O'limdan keyin davom etish uchun ishlatiladigan beletlar soni.
  int get tickets => _prefs.getInt(_kTickets) ?? welcomeTickets;

  /// Bitta belet sarflaydi. Belet qolmagan bo'lsa `false` qaytaradi.
  Future<bool> spendTicket() async {
    final left = tickets;
    if (left <= 0) return false;
    await _prefs.setInt(_kTickets, left - 1);
    return true;
  }

  Future<void> addTickets(int count) =>
      _prefs.setInt(_kTickets, tickets + count);

  Difficulty get difficulty =>
      Difficulty.fromName(_prefs.getString(_kDifficulty));

  /// Saqlangan til; hali tanlanmagan bo'lsa `null`.
  AppLanguage? get language {
    final code = _prefs.getString(_kLanguage);
    return code == null ? null : AppLanguage.fromCode(code);
  }

  Future<void> setColorIndex(int value) => _prefs.setInt(_kColor, value);

  Future<void> setDifficulty(Difficulty value) =>
      _prefs.setString(_kDifficulty, value.name);

  Future<void> setLanguage(AppLanguage value) =>
      _prefs.setString(_kLanguage, value.code);

  /// Natijani saqlaydi. Yangi rekord bo'lsa `true` qaytaradi.
  Future<bool> submitResult({
    required double percent,
    required int kills,
  }) async {
    var isRecord = false;
    if (percent > bestPercent) {
      await _prefs.setDouble(_kRecord, percent);
      isRecord = true;
    }
    if (kills > bestKills) {
      await _prefs.setInt(_kKills, kills);
    }
    return isRecord;
  }

  Future<void> resetRecord() async {
    await _prefs.remove(_kRecord);
    await _prefs.remove(_kKills);
  }
}
