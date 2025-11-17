import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

// Экраны приложения
import 'features/route/route_screen.dart';
import 'features/activation/activation_screen.dart';
import 'features/qrscan/scan_screen.dart';
import 'features/faq/faq_screen.dart';

// Экран с WebView (файл: lib/screens/qr_web_page.dart)
import 'screens/qr_web_page.dart';
import 'features/player/player_screen.dart';

/// Базовый адрес, где лежат ваши веб-сцены (GitHub Pages / другой хостинг).
/// ОБЯЗАТЕЛЬНО поправьте при необходимости.
const String kWebBase = 'https://ivarte.github.io/Drink_story';

/// Как формируется ссылка на страницу сцены.
/// Если ваши сцены лежат иначе — измените шаблон (например, '/scenes/$id/').
String _sceneUrl(String sceneId) => '$kWebBase/$sceneId/index.html';

void main() => runApp(const DrinkStoryApp());

class DrinkStoryApp extends StatelessWidget {
  const DrinkStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const RouteScreen()),
        GoRoute(path: '/activate', builder: (_, __) => const ActivateScreen()),
        GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),

        // При переходе вида /player/:sceneId
        // - on web: open the Flutter `PlayerScreen` which plays `scenes/<id>.m4a`
        // - on native: open the WebView page that hosts the scene HTML
        GoRoute(
          path: '/player/:sceneId',
          builder: (_, state) {
            final sceneId = state.pathParameters['sceneId']!;
            if (kIsWeb) {
              return PlayerScreen(sceneId: sceneId);
            }
            final url = _sceneUrl(sceneId);
            return QrWebPage(url: url);
          },
        ),

        GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      title: 'Drink Story',
      debugShowCheckedModeBanner: false,
    );
  }
}
