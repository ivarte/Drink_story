// lib/features/player/player_controller.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import '../../core/storage.dart';

class PlayerController {
  final _p = AudioPlayer();

  Future<void> playSceneId(String sceneId) async {
    if (kIsWeb) {
      // On GitHub Pages, we need the full URL: https://ivarte.github.io/Drink_story/scenes/{sceneId}.m4a
      // The relative path /scenes/ fails because app is at /Drink_story/
      // Solution: Use a relative path that works from the app root (./scenes/ or scenes/)
      final sceneUrl = 'scenes/$sceneId.m4a';
      
      _logWeb('Loading scene: $sceneId');
      _logWeb('Audio URL: $sceneUrl (relative - will resolve from app base href)');
      
      try {
        await _p.setUrl(sceneUrl);
        _logWeb('Audio URL set successfully.');
      } catch (e) {
        _logWeb('Error loading URL: $e');
        rethrow;
      }
    } else {
      final m = await AppStorage.loadManifest();
      final rel = m?.byId(sceneId)?.file ?? 'scenes/$sceneId.m4a'; // fallback
      final f = await AppStorage.sceneFile(rel);
      await _p.setFilePath(f.path);
    }
    
    try {
      await _p.play();
      if (kIsWeb) _logWeb('Playback started.');
    } catch (e) {
      if (kIsWeb) _logWeb('Error during playback: $e');
      rethrow;
    }
  }

  void toggle() => _p.playing ? _p.pause() : _p.play();
  void fwd10() => _p.seek(_p.position + const Duration(seconds: 10));
  void back10() => _p.seek(_p.position - const Duration(seconds: 10));
}

// Web-only logging helper
void _logWeb(String msg) {
  if (kIsWeb) {
    // ignore: avoid_print
    print('🎵 PlayerController: $msg');
  }
}
