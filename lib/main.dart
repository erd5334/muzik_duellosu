import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/matchmaking_screen.dart';
import 'screens/arena_screen.dart';
import 'screens/match_result_screen.dart';

import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.init();
  // Koyu durum çubuğu ve gezinme çubuğu
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const MuzikDuellosuApp(),
    ),
  );
}

class MuzikDuellosuApp extends StatelessWidget {
  const MuzikDuellosuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahne Senin: Şarkıyı Bil Bakalım',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    switch (game.status) {
      case GameStatus.searchingOpponent:
      case GameStatus.waitingFriendInRoom:
      case GameStatus.opponentFound:
        return const MatchmakingScreen();

      case GameStatus.playing:
      case GameStatus.roundIntro:
      case GameStatus.roundResult:
        return const ArenaScreen();

      case GameStatus.matchOver:
        return const MatchResultScreen();

      case GameStatus.idle:
      case GameStatus.error:
        return const HomeScreen();
    }
  }
}
