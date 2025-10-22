import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Формат QR (строка): `STH1.<base64url(payload)>.<base64url(signature)>`
/// где payload: `{"r":"<routeId>","s":"<sceneId>"}`
/// Совет: старайтесь избегать угловых скобок в doc-комментариях (иначе dartdoc
/// считает их HTML). Оборачивайте в обратные кавычки, как выше.
class QrValidator {
  late final SimplePublicKey _pub;

  Future<void> init() async {
    // В assets/public_key.pem хранится публичный ключ в PEM/SPKI
    final pem = await rootBundle.loadString('assets/public_key.pem');
    final b64 = pem.replaceAll(RegExp(r'-----.*KEY-----|\s'), '');
    final der = base64.decode(b64); // SubjectPublicKeyInfo (DER)
    _pub = SimplePublicKey(der, type: KeyPairType.p256);
  }

  /// Возвращает sceneId, если подпись валидна и routeId совпадает, иначе null.
  Future<String?> validateAndGetSceneId(String raw, String requiredRouteId) async {
    final parts = raw.split('.');
    if (parts.length != 3 || parts[0] != 'STH1') return null;

    final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
    final sigBytes     = base64Url.decode(base64Url.normalize(parts[2]));
    final payload = jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
    if (payload['r'] != requiredRouteId || payload['s'] == null) return null;

    // ✅ Правильный вызов cryptography: именованный конструктор p256
    final ok = await Ecdsa.p256(Sha256()).verify(
      payloadBytes,
      signature: Signature(sigBytes, publicKey: _pub),
    );
    return ok ? payload['s'] as String : null;
  }
}
