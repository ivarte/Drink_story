// lib/features/player/player_controller.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import '../../core/storage.dart';

class PlayerController {
  final _p = AudioPlayer();

  Future<void> playSceneId(String sceneId) async {
    if (kIsWeb) {
      await _p.setUrl('scenes/$sceneId.m4a'); // web: раздаём из /web/scenes/ это относительный путь, чтобы работать и на GitHub Pages, и в Codespaces
    } else {
      final m = await AppStorage.loadManifest();
      final rel = m?.byId(sceneId)?.file ?? 'scenes/$sceneId.m4a'; // fallback
      final f = await AppStorage.sceneFile(rel);
      await _p.setFilePath(f.path);
    }
    await _p.play();
  }

  void toggle() => _p.playing ? _p.pause() : _p.play();
  void fwd10() => _p.seek(_p.position + const Duration(seconds: 10));
  void back10() => _p.seek(_p.position - const Duration(seconds: 10));
}
