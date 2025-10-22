import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../../core/qr_validator.dart';
import '../../core/config.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _validator = QrValidator();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _validator.init().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext _) {
    // не используем параметр build-метода `context` в async-колбэках
    return Scaffold(
      appBar: AppBar(title: const Text('Сканируйте QR в баре')),
      body: _ready
          ? MobileScanner(onDetect: (capture) async {
              final raw = capture.barcodes.first.rawValue ?? '';

              // валидация подписи; DEV-фоллбек — принимать сырую строку
              final validated = await _validator
                  .validateAndGetSceneId(raw, AppConfig.routeId);
              final sceneId = validated ?? raw;

              if (!mounted) return; // обязательно перед использованием context

              if (sceneId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Неверный QR')),
                );
                return;
              }

              GoRouter.of(context).go('/player/$sceneId');
            })
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
