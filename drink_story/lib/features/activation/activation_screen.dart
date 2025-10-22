import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/installer.dart';
import '../../core/storage.dart';
import '../../data/models.dart';

class ActivateScreen extends StatefulWidget {
  const ActivateScreen({super.key});
  @override
  State<ActivateScreen> createState() => _ActivateScreenState();
}

class _ActivateScreenState extends State<ActivateScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _msg;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() {
      _busy = true;
      _msg = null;
    });

    String localMsg;

    try {
      final token = _code.text.trim();

      // === DEMO-ветка: ставим пакет с same-origin (/route.zip) и выходим ===
      if (token.toUpperCase() == 'DEMO') {
        const demoUrl = String.fromEnvironment('DEMO_PACKAGE_URL');
        const demoSha = String.fromEnvironment('DEMO_PACKAGE_SHA256');

        // на всякий случай лог в консоль
        // ignore: avoid_print
        print('DEMO url=$demoUrl sha=$demoSha');

        if (demoUrl.isEmpty || demoSha.isEmpty) {
          localMsg = 'DEMO: не заданы DEMO_PACKAGE_URL/DEMO_PACKAGE_SHA256';
        } else {
          // ВАЖНО: отдельный Dio() БЕЗ baseUrl, чтобы /route.zip был same-origin
          await Installer(Dio()).installPackage(Uri.parse(demoUrl), demoSha);
          localMsg = 'Готово: DEMO пакет установлен.';
        }

        if (!mounted) return;
        setState(() {
          _busy = false;
          _msg = localMsg;
        });
        return; // критично — не идём дальше в ApiClient().activate()
      }

      // === Прод-ветка: обычная активация через бэкенд ===
      final api = ApiClient();
      final r = await api.activate(token); // ожидаем JSON с полями из спеки

      await AppStorage.saveLicense(License(
  licenseId: 'demo',
  routeId: AppConfig.routeId, // ← вот так
  signature: 'demo',
  activatedAt: DateTime.now(),
));


      await Installer(api.dio).installPackage(
        Uri.parse(r['package_url']),
        (r['checksum_sha256'] as String),
      );

      localMsg = 'Готово: пакет установлен.';
    } catch (e) {
      localMsg = 'Ошибка: $e';
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _msg = localMsg;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Активация')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Код билета',
                hintText: 'Например: DEMO',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _activate,
              child: _busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Активировать'),
            ),
            if (_msg != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_msg!),
              ),
          ]),
        ),
      );
}
