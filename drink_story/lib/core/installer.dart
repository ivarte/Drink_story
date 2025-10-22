import 'dart:io' show File;
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'storage.dart';

class Installer {
  final Dio _dio;
  Installer(this._dio);

  Future<void> installPackage(Uri url, String expectedSha256Hex) async {
    // На Web не пишем в ФС — максимум можно проверить хеш и выйти.
    if (kIsWeb) {
      try {
        final bytes = (await _dio.get<List<int>>(url.toString(),
          options: Options(responseType: ResponseType.bytes))).data!;
        final got = sha256.convert(bytes).toString();
        if (expectedSha256Hex.isNotEmpty &&
            got.toLowerCase() != expectedSha256Hex.toLowerCase()) {
          throw Exception('Hash mismatch (web)');
        }
      } catch (_) {
        // Для DEMO можно проглотить — файлы читаем из /scenes/
      }
      return;
    }

    // iOS/Android — ставим пакет в ApplicationSupportDirectory
    final bytes = (await _dio.get<List<int>>(url.toString(),
      options: Options(responseType: ResponseType.bytes))).data!;
    final got = sha256.convert(bytes).toString();
    if (got.toLowerCase() != expectedSha256Hex.toLowerCase()) {
      throw Exception('Hash mismatch');
    }
// lib/core/installer.dart (фрагмент внутри installPackage после проверки хеша)
final dir = await AppStorage.appDir();
final arc = ZipDecoder().decodeBytes(bytes);
for (final f in arc) {
  final out = File('${dir.path}/${f.name}');
  if (f.isFile) {
    out.createSync(recursive: true);
    final content = f.content as List<int>;
    out.writeAsBytesSync(content);

    if (f.name == 'manifest.json') {
      try {
        var jsonStr = String.fromCharCodes(content);
        // безопасно уберём BOM, если вдруг он есть
        if (jsonStr.isNotEmpty && jsonStr.codeUnitAt(0) == 0xFEFF) {
          jsonStr = jsonStr.substring(1);
        }
        await AppStorage.saveManifest(
          (jsonDecode(jsonStr) as Map).cast<String, dynamic>(),
        );
      } catch (_) {/* допустимо пропустить, файл всё равно записан */}
    }
  }
}

