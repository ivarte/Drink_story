import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Импорты экранов
import 'features/route/route_screen.dart';
import 'features/activation/activation_screen.dart';
import 'features/qrscan/scan_screen.dart';
import 'features/player/player_screen.dart';
import 'features/faq/faq_screen.dart';

void main() => runApp(const DrinkStoryApp());

class DrinkStoryApp extends StatelessWidget {
  const DrinkStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const RouteScreen()),
      GoRoute(path: '/activate', builder: (_, __) => const ActivateScreen()),
      GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
      GoRoute(
        path: '/player/:sceneId',
        builder: (_, s) => PlayerScreen(sceneId: s.pathParameters['sceneId']!),
      ),
      GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
    ]);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Drink Story',
      debugShowCheckedModeBanner: false,
    );
  }
}
