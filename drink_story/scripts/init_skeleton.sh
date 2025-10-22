# scripts/init_skeleton.sh
set -euo pipefail

# 0) проверка, что вы в корне Flutter-проекта
test -f pubspec.yaml || { echo "Запустите из корня проекта (рядом с pubspec.yaml)"; exit 1; }

# 1) Папки
mkdir -p lib/core lib/data \
  lib/features/{activation,route,qrscan,player,faq} \
  assets scripts

# 2) Зависимости (если ещё не добавляли)
flutter pub add go_router flutter_riverpod \
  just_audio audio_service mobile_scanner \
  dio path_provider archive crypto \
  uni_links url_launcher cryptography >/dev/null

# 3) Ассеты: публичный ключ (заглушка)
cat > assets/public_key.pem <<'PEM'
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAA==
-----END PUBLIC KEY-----
PEM

# 4) Подключим ассеты в pubspec.yaml (вставим рядом с uses-material-design)
if ! grep -q 'assets/public_key.pem' pubspec.yaml; then
  awk '{
    print $0
    if ($0 ~ /uses-material-design: *true/ && !p) {
      print "  assets:"
      print "    - assets/public_key.pem"
      p=1
    }
  }' pubspec.yaml > pubspec.yaml.tmp && mv pubspec.yaml.tmp pubspec.yaml
fi

# 5) Файлы: каркас кода

# 5.1 main.dart (роутер + заглушки экранов)
cat > lib/main.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const RouteScreen()),
      GoRoute(path: '/activate', builder: (_, __) => const ActivateScreen()),
      GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
      GoRoute(path: '/player/:sceneId',
        builder: (_, s) => PlayerScreen(sceneId: s.pathParameters['sceneId']!)),
      GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
    ]);
    return MaterialApp.router(title: 'Drink Story', routerConfig: router);
  }
}
DART

# 5.2 core/config.dart
cat > lib/core/config.dart <<'DART'
class AppConfig {
  static const apiBase =
      String.fromEnvironment('API_BASE', defaultValue: 'https://api.example.com');
  static const routeId =
      String.fromEnvironment('ROUTE_ID', defaultValue: 'krasnoyarsk_cocktail_v1');
}
DART

# 5.3 core/storage.dart
cat > lib/core/storage.dart <<'DART'
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data/models.dart';

class AppStorage {
  static Future<Directory> appDir() => getApplicationSupportDirectory();

  static Future<File> _file(String name) async =>
      File('${(await appDir()).path}/$name');

  static Future<void> saveLicense(License l) async {
    final f = await _file('license.json'); f.createSync(recursive: true);
    await f.writeAsString(jsonEncode(l.toJson()));
  }

  static Future<License?> loadLicense() async {
    final f = await _file('license.json');
    if (!f.existsSync()) return null;
    return License.fromJson(jsonDecode(await f.readAsString()));
  }

  static Future<void> saveManifest(Map<String, dynamic> j) async {
    final f = await _file('manifest.json'); f.createSync(recursive: true);
    await f.writeAsString(jsonEncode(j));
  }

  static Future<RouteManifest?> loadManifest() async {
    final f = await _file('manifest.json');
    if (!f.existsSync()) return null;
    return RouteManifest.fromJson(jsonDecode(await f.readAsString()));
  }

  static Future<File> sceneFile(String relativePath) async =>
      File('${(await appDir()).path}/$relativePath');
}
DART

# 5.4 core/installer.dart
cat > lib/core/installer.dart <<'DART'
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'storage.dart';

class Installer {
  final Dio _dio;
  Installer(this._dio);

  Future<void> installPackage(Uri url, String expectedSha256Hex) async {
    final bytes = (await _dio.get<List<int>>(url.toString(),
      options: Options(responseType: ResponseType.bytes))).data!;
    final got = sha256.convert(bytes).toString();
    if (got.toLowerCase() != expectedSha256Hex.toLowerCase()) {
      throw Exception('Hash mismatch');
    }
    final dir = await AppStorage.appDir();
    final arc = ZipDecoder().decodeBytes(bytes);
    for (final f in arc) {
      final out = File('${dir.path}/${f.name}');
      if (f.isFile) {
        out.createSync(recursive: true);
        out.writeAsBytesSync(f.content as List<int>);
      }
    }
  }
}
DART

# 5.5 core/api_client.dart
cat > lib/core/api_client.dart <<'DART'
import 'package:dio/dio.dart';
import 'config.dart';

class ApiClient {
  final Dio dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Возвращает:
  /// {license_id, route_id, signature, package_url, checksum_sha256, ...}
  Future<Map<String, dynamic>> activate(String token) async {
    final r = await dio.post('/license/activate', data: {'token': token});
    return (r.data as Map).cast<String, dynamic>();
  }
}
DART

# 5.6 core/qr_validator.dart
cat > lib/core/qr_validator.dart <<'DART'
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart' show rootBundle;

class QrValidator {
  late final SimplePublicKey _pub;

  Future<void> init() async {
    final pem = await rootBundle.loadString('assets/public_key.pem');
    final b64 = pem.replaceAll(RegExp(r'-----.*KEY-----|\s'), '');
    final der = base64.decode(b64); // SubjectPublicKeyInfo (DER)
    _pub = SimplePublicKey(der, type: KeyPairType.p256);
  }

  /// Ожидается формат: STH1.<base64url(payload)>.<base64url(signature)>
  /// payload: {"r":"<routeId>","s":"<sceneId>"}
  Future<String?> validateAndGetSceneId(String raw, String requiredRouteId) async {
    final parts = raw.split('.');
    if (parts.length != 3 || parts[0] != 'STH1') return null;

    final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
    final sigBytes = base64Url.decode(base64Url.normalize(parts[2]));
    final payload = jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;

    if (payload['r'] != requiredRouteId || payload['s'] == null) return null;

    final ok = await Ecdsa(p256, Sha256())
        .verify(payloadBytes, signature: Signature(sigBytes, publicKey: _pub));
    return ok ? payload['s'] as String : null;
  }
}
DART

# 5.7 data/models.dart
cat > lib/data/models.dart <<'DART'
class License {
  final String licenseId, routeId, signature;
  final DateTime activatedAt;
  License({
    required this.licenseId,
    required this.routeId,
    required this.signature,
    required this.activatedAt,
  });

  factory License.fromJson(Map<String, dynamic> j) => License(
        licenseId: j['license_id'],
        routeId: j['route_id'],
        signature: j['signature'],
        activatedAt: DateTime.parse(j['activated_at'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        'license_id': licenseId,
        'route_id': routeId,
        'signature': signature,
        'activated_at': activatedAt.toIso8601String(),
      };
}

class Scene {
  final String id, file, type;
  final String? unlock, nextId;
  Scene({required this.id, required this.file, required this.type, this.unlock, this.nextId});

  factory Scene.fromJson(Map<String, dynamic> j) => Scene(
        id: j['id'],
        file: j['file'],
        type: j['type'],
        unlock: j['unlock'],
        nextId: j['next'],
      );
}

class RouteManifest {
  final String routeId, version, checksumSha256, title;
  final int durationMin;
  final List<Scene> scenes;

  RouteManifest({
    required this.routeId,
    required this.version,
    required this.title,
    required this.durationMin,
    required this.scenes,
    required this.checksumSha256,
  });

  factory RouteManifest.fromJson(Map<String, dynamic> j) => RouteManifest(
        routeId: j['route_id'],
        version: j['version'] ?? '1.0.0',
        title: j['title'] ?? '',
        durationMin: j['duration_min'] ?? 0,
        scenes: (j['scenes'] as List? ?? [])
            .map((e) => Scene.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        checksumSha256: j['checksum_sha256'] ?? '',
      );

  Scene? byId(String id) {
    for (final s in scenes) {
      if (s.id == id) return s;
    }
    return null;
  }
}
DART

# 5.8 features: экраны (заглушки, чтобы проект сразу собирался)
cat > lib/features/activation/activation_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/installer.dart';
import '../../core/storage.dart';
import '../../data/models.dart';

class ActivateScreen extends StatefulWidget {
  const ActivateScreen({super.key});
  @override State<ActivateScreen> createState() => _S();
}
class _S extends State<ActivateScreen> {
  final _code = TextEditingController(); bool _busy=false; String? _msg;
  Future<void> _activate() async {
    setState(()=>_busy=true); _msg=null;
    try{
      final api = ApiClient();
      final r = await api.activate(_code.text.trim());
      await AppStorage.saveLicense(License(
        licenseId: r['license_id'], routeId: r['route_id'],
        signature: r['signature'] ?? '', activatedAt: DateTime.now()));
      await Installer(api.dio).installPackage(
        Uri.parse(r['package_url']), r['checksum_sha256']);
      setState(()=>_msg='Готово: пакет установлен.');
    }catch(e){ setState(()=>_msg='Ошибка: $e'); }
    finally{ setState(()=>_busy=false); }
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar: AppBar(title: const Text('Активация')),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(
      children: [
        TextField(controller:_code, decoration: const InputDecoration(labelText:'Код билета')),
        const SizedBox(height:12),
        ElevatedButton(onPressed:_busy?null:_activate, child:_busy?const CircularProgressIndicator():const Text('Активировать')),
        if(_msg!=null) Padding(padding: const EdgeInsets.only(top:12), child: Text(_msg!)),
      ],
    )),
  );
}
DART

cat > lib/features/route/route_screen.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Маршрут: 4 бара')),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ElevatedButton(onPressed: ()=>context.go('/activate'), child: const Text('Активация')),
        const SizedBox(height:8),
        ElevatedButton(onPressed: ()=>context.go('/scan'), child: const Text('Сканировать QR')),
        const SizedBox(height:8),
        ElevatedButton(onPressed: ()=>context.go('/faq'), child: const Text('FAQ / 18+')),
      ])),
    );
  }
}
DART

cat > lib/features/qrscan/scan_screen.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканируйте QR в баре')),
      body: MobileScanner(onDetect: (capture) async {
        final raw = capture.barcodes.first.rawValue ?? '';
        // Здесь позже: валидация подписи и routeId
        final sceneId = raw; // временно
        if (sceneId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неверный QR')));
          return;
        }
        if (context.mounted) context.go('/player/$sceneId');
      }),
    );
  }
}
DART

cat > lib/features/player/player_controller.dart <<'DART'
import 'package:just_audio/just_audio.dart';

class PlayerController {
  final _p = AudioPlayer();
  Future<void> setAndPlay(String filePath) async {
    await _p.setFilePath(filePath);
    await _p.play();
  }
  void toggle() => _p.playing ? _p.pause() : _p.play();
  void fwd10() => _p.seek(_p.position + const Duration(seconds: 10));
  void back10() => _p.seek(_p.position - const Duration(seconds: 10));
}
DART

cat > lib/features/player/player_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../core/storage.dart';
import 'player_controller.dart';

class PlayerScreen extends StatefulWidget {
  final String sceneId;
  const PlayerScreen({super.key, required this.sceneId});
  @override State<PlayerScreen> createState()=>_S();
}
class _S extends State<PlayerScreen> {
  final _pc = PlayerController(); String? _path;
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    // В MVP файл хранится в офлайн-пакете; пока подставим относительный путь = id
    final f = await AppStorage.sceneFile('scenes/${widget.sceneId}.m4a');
    setState(()=>_path=f.path);
    await _pc.setAndPlay(f.path);
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar: AppBar(title: Text('Сцена ${widget.sceneId}')),
    body: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(onPressed:_pc.back10, icon: const Icon(Icons.replay_10)),
      IconButton(onPressed:_pc.toggle, icon: const Icon(Icons.play_arrow)),
      IconButton(onPressed:_pc.fwd10, icon: const Icon(Icons.forward_10)),
    ])),
  );
}
DART

cat > lib/features/faq/faq_screen.dart <<'DART'
import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Правила и 18+')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('18+. Пейте ответственно. Не садитесь за руль. Наушники обязательны.'),
    ),
  );
}
DART

# 6) Быстрый fetch зависимостей
flutter pub get >/dev/null

echo "✅ Готово: каркас создан. Проверьте pubspec.yaml (assets) и собирайте."

