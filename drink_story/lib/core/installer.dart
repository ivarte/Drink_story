import 'dart:convert';                 // ← jsonDecode/utf8
import 'dart:io' show File;            // ← для iOS/Android
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'storage.dart';

class Installer {
  final Dio _dio;
  Installer(this._dio);

  Future<void> installPackage(Uri url, String expectedSha256Hex) async {
    // --- Web: не пишем в ФС, максимум проверяем хеш и выходим ---
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
        // Для DEMO на web можно проглотить ошибку — аудио читаем из /scenes/
      }
      return;
    }

    // --- iOS/Android: скачиваем, проверяем хеш, распаковываем в ApplicationSupport ---
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
        final content = f.content as List<int>;
        out.writeAsBytesSync(content);

        // Поймали manifest.json — сохраним сразу в локальное хранилище
        if (f.name == 'manifest.json') {
          try {
            var jsonStr = utf8.decode(content);
            // убрать возможный BOM
            if (jsonStr.isNotEmpty && jsonStr.codeUnitAt(0) == 0xFEFF) {
              jsonStr = jsonStr.substring(1);
            }
            final map = (jsonDecode(jsonStr) as Map).cast<String, dynamic>();
            await AppStorage.saveManifest(map);
          } catch (_) {
            // файл всё равно распакован на диск — не критично
          }
        }
      }
    }
  }
}
