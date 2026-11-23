import 'package:flutter/material.dart';

import '../game/logic/difficulty.dart';
import '../game/render/game_theme.dart';
import '../game/render/palette.dart';
import '../i18n/app_language.dart';
import '../i18n/l10n.dart';
import '../services/audio_service.dart';
import '../storage/settings_store.dart';
import 'theme/arcade.dart';
import 'widgets/ui_kit.dart';

/// Sozlamalar: ko'rinish (rang, uslub), o'yin (qiyinlik, til) va
/// ovoz (musiqa, effektlar, vibratsiya).
///
/// Bosh menyuda faqat o'ynash qoladi — tanlovlar shu yerga yig'ilgan.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store, required this.audio});

  final SettingsStore store;
  final AudioService audio;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _colorIndex = widget.store.colorIndex;
  late GameTheme _theme = widget.store.theme;
  late Difficulty _difficulty = widget.store.difficulty;
  late bool _music = widget.store.musicEnabled;
  late bool _sound = widget.store.soundEnabled;
  late bool _vibration = widget.store.vibrationEnabled;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final accent = Palette.head(_colorIndex);

    return Scaffold(
      backgroundColor: Arcade.bg,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: t.settings,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                children: [
                  // ——— Ko'rinish ———
                  GamePanel(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionLabel(t.sectionAppearance),
                        Text(t.chooseColor, style: Arcade.body),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < Palette.colorCount; i++)
                              ColorChip(
                                index: i,
                                selected: i == _colorIndex,
                                onTap: () async {
                                  widget.audio.tap();
                                  setState(() => _colorIndex = i);
                                  await widget.store.setColorIndex(i);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(t.themeLabel, style: Arcade.body),
                        const SizedBox(height: 10),
                        ChoiceChips<GameTheme>(
                          values: GameTheme.all,
                          selected: _theme,
                          labelOf: (th) => th.name,
                          onSelected: (th) async {
                            widget.audio.tap();
                            setState(() {
                              _theme = th;
                              Palette.theme = th;
                            });
                            await widget.store.setTheme(th);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ——— O'yin ———
                  GamePanel(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionLabel(t.sectionGame),
                        Text(t.difficulty, style: Arcade.body),
                        const SizedBox(height: 10),
                        ChoiceChips<Difficulty>(
                          values: Difficulty.values,
                          selected: _difficulty,
                          labelOf: t.difficultyName,
                          onSelected: (d) async {
                            widget.audio.tap();
                            setState(() => _difficulty = d);
                            await widget.store.setDifficulty(d);
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(t.language, style: Arcade.body),
                        const SizedBox(height: 10),
                        _LanguageChips(audio: widget.audio),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ——— Ovoz va titrash ———
                  GamePanel(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionLabel(t.sectionAudio),
                        SwitchTile(
                          icon: Icons.music_note_rounded,
                          label: t.music,
                          value: _music,
                          accent: accent,
                          onChanged: (v) async {
                            setState(() => _music = v);
                            await widget.store.setMusicEnabled(v);
                            await widget.audio.setMusicEnabled(v);
                          },
                        ),
                        SwitchTile(
                          icon: Icons.volume_up_rounded,
                          label: t.sound,
                          value: _sound,
                          accent: accent,
                          onChanged: (v) async {
                            setState(() => _sound = v);
                            await widget.store.setSoundEnabled(v);
                            await widget.audio.setSoundEnabled(v);
                            // Yoqilganda darhol eshitilsin.
                            widget.audio.tap();
                          },
                        ),
                        SwitchTile(
                          icon: Icons.vibration_rounded,
                          label: t.vibration,
                          value: _vibration,
                          accent: accent,
                          onChanged: (v) async {
                            setState(() => _vibration = v);
                            await widget.store.setVibrationEnabled(v);
                            widget.audio.setVibrationEnabled(v);
                            // Yoqilganda darhol sezilsin.
                            widget.audio.tap();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tilni chiplar bilan tanlash — menyudagi ochiluvchi ro'yxat o'rniga.
class _LanguageChips extends StatelessWidget {
  const _LanguageChips({required this.audio});

  final AudioService audio;

  @override
  Widget build(BuildContext context) {
    final controller = L10n.controllerOf(context);
    return ChoiceChips<AppLanguage>(
      values: AppLanguage.values,
      selected: controller.language,
      labelOf: (l) => l.nativeName,
      onSelected: (l) {
        audio.tap();
        controller.setLanguage(l);
      },
    );
  }
}
