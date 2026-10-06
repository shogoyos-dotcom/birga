import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/countries.dart';
import '../game/logic/player_profile.dart';
import '../game/render/palette.dart';
import '../i18n/l10n.dart';
import '../storage/settings_store.dart';
import 'theme/arcade.dart';
import 'widgets/avatar_view.dart';
import 'widgets/ui_kit.dart';

/// Profil ekrani: taxallus va avatar (emoji / odam tasviri / bayroq).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.store,
    required this.colorIndex,
  });

  final SettingsStore store;
  final int colorIndex;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _name = TextEditingController(
    text: widget.store.nickname ?? '',
  );
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: switch (_avatar.kind) {
      AvatarKind.emoji => 0,
      AvatarKind.figure => 1,
      AvatarKind.flag => 2,
    },
  );
  late Avatar _avatar = widget.store.avatar;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = L10n.of(context);
    await widget.store.setNickname(PlayerProfile.sanitize(_name.text, t.you));
    await widget.store.setAvatar(_avatar);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.profileSaved),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  void _pick(Avatar a) => setState(() => _avatar = a);

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final accent = Palette.head(widget.colorIndex);

    return Scaffold(
      backgroundColor: Arcade.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Sarlavha qatori.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Arcade.text,
                    tooltip: t.back,
                  ),
                  Expanded(
                    child: Text(t.profile.toUpperCase(), style: Arcade.title),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                children: [
                  // Tanlangan avatar + taxallus.
                  GamePanel(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Arcade.surface,
                            borderRadius: BorderRadius.circular(Arcade.radius),
                            border: Border.all(color: accent, width: 2.5),
                            boxShadow: Arcade.glow(accent, strength: 0.7),
                          ),
                          child: AvatarView(avatar: _avatar, size: 56),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _name,
                            maxLength: PlayerProfile.maxNicknameLength,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _save(),
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\n')),
                            ],
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Arcade.text,
                            ),
                            decoration: InputDecoration(
                              labelText: t.nickname.toUpperCase(),
                              labelStyle: Arcade.section,
                              hintText: t.nicknameHint,
                              hintStyle: Arcade.body.copyWith(
                                color: Arcade.textFaint,
                              ),
                              counterText: '',
                              isDense: true,
                              filled: true,
                              fillColor: Arcade.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  Arcade.radiusSmall + 2,
                                ),
                                borderSide: const BorderSide(
                                  color: Arcade.stroke,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  Arcade.radiusSmall + 2,
                                ),
                                borderSide: const BorderSide(
                                  color: Arcade.stroke,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  Arcade.radiusSmall + 2,
                                ),
                                borderSide: BorderSide(color: accent, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(t.avatarLabel),
                  GamePanel(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabs,
                          labelColor: accent,
                          indicatorColor: accent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Arcade.stroke,
                          unselectedLabelColor: Arcade.textFaint,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          tabs: [
                            Tab(text: t.tabEmoji),
                            Tab(text: t.tabFigure),
                            Tab(text: t.tabFlag),
                          ],
                          onTap: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        // Har bir varaq balandligi o'zi bilan belgilanadi,
                        // shuning uchun TabBarView emas — faqat tanlangani
                        // quriladi.
                        switch (_tabs.index) {
                          0 => _emojiGrid(accent),
                          1 => _figureGrid(accent),
                          _ => _flagGrid(accent, t.searchCountry),
                        },
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GameButton(
                    label: t.save,
                    icon: Icons.check_rounded,
                    color: accent,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiGrid(Color accent) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      for (final e in kAvatarEmojis)
        AvatarChip(
          avatar: Avatar.emoji(e),
          selected: _avatar == Avatar.emoji(e),
          accent: accent,
          onTap: () => _pick(Avatar.emoji(e)),
        ),
    ],
  );

  Widget _figureGrid(Color accent) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      for (var i = 0; i < kFigureCount; i++)
        AvatarChip(
          avatar: Avatar.figure(i),
          selected: _avatar == Avatar.figure(i),
          accent: accent,
          onTap: () => _pick(Avatar.figure(i)),
        ),
    ],
  );

  Widget _flagGrid(Color accent, String searchLabel) {
    final list = searchCountries(_query);
    return Column(
      children: [
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 15, color: Arcade.text),
          decoration: InputDecoration(
            hintText: searchLabel,
            hintStyle: Arcade.body.copyWith(color: Arcade.textFaint),
            isDense: true,
            filled: true,
            fillColor: Arcade.surface,
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: Arcade.textFaint,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        // 249 bayroq — ro'yxat baland bo'lmasligi uchun o'z ichida
        // aylantiriladi.
        SizedBox(
          height: 250,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.35,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              final a = Avatar.flag(c.code);
              return AvatarChip(
                avatar: a,
                selected: _avatar == a,
                accent: accent,
                caption: c.name,
                onTap: () => _pick(a),
              );
            },
          ),
        ),
      ],
    );
  }
}
