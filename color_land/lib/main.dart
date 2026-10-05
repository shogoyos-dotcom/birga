import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/logic/game_config.dart';
import 'game/render/palette.dart';
import 'ui/game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ColorLandApp());
}

class ColorLandApp extends StatelessWidget {
  const ColorLandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Land',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.heads.first),
        scaffoldBackgroundColor: Palette.outside,
      ),
      home: const GameScreen(config: GameConfig(botCount: 0), colorIndex: 0),
    );
  }
}
