import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

import 'core/game_state.dart';
import 'core/app_theme.dart';
import 'screens/menu_screen.dart';
import 'screens/gameplay_screen.dart';
import 'screens/result_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/game_over_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(1024, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Collor',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState()..reset(),
      child: const CollorApp(),
    ),
  );
}

class CollorApp extends StatelessWidget {
  const CollorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppTheme.accent,
          surface: AppTheme.bg,
          error: AppTheme.danger,
        ),
        scaffoldBackgroundColor: AppTheme.bg,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const MainRouter(),
    );
  }
}

class MainRouter extends StatelessWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.select((GameState g) => g.phase);
    
    switch (phase) {
      case 'title':
        return const MenuScreen();
      case 'play':
      case 'executing':
      case 'scoring':
        return const GameplayScreen();
      case 'result':
        return const ResultScreen();
      case 'shop':
        return const ShopScreen();
      case 'gameover':
        return const GameOverScreen();
      default:
        return const MenuScreen();
    }
  }
}
