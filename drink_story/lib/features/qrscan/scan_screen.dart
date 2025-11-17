import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../../core/qr_validator.dart';
import '../../core/config.dart';
import '../../screens/qr_web_page.dart'; // <- добавили

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _validator = QrValidator();
  bool _ready = false;
  bool _handling = false; // <- защита от повторных срабатываний

  @override
  void initState() {
    super.initState();
    _validator.init().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext _) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканируйте QR в баре')),
      body: _ready
          ? MobileScanner(
              onDetect: (capture) async {
                if (_handling) return;
                _handling = true;
                try {
                  final raw = capture.barcodes.first.rawValue ?? '';

                  // 1) Если это URL — открываем во встроенном WebView (автоплей разрешён)
                  final uri = Uri.tryParse(raw);
                  final isHttp = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
                  if (isHttp) {
                    if (!mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => QrWebPage(url: uri!.toString())),
                    );
                    return; // после возврата можно снова сканировать
                  }

                  // 2) Иначе — как раньше: валидируем и ведём в плеер по sceneId
                  final validated =
                      await _validator.validateAndGetSceneId(raw, AppConfig.routeId);
                  final sceneId = validated ?? raw;

                  if (!mounted) return;
                  if (sceneId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Неверный QR')),
                    );
                    return;
                  }

                  GoRouter.of(context).go('/player/$sceneId');
                } finally {
                  _handling = false;
                }
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
