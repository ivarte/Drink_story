import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'player_controller.dart';

class PlayerScreen extends StatefulWidget {
  final String sceneId;
  const PlayerScreen({super.key, required this.sceneId});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _pc = PlayerController();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Do not attempt autoplay on web (browsers block autoplay).
    // On mobile/desktop we can try to autoplay immediately.
    if (!kIsWeb) {
      _startPlayback();
    } else {
      // On web, log the scene id for debugging and show Play button
      // ignore: avoid_print
      print('🎬 PlayerScreen (web): ready for scene ${widget.sceneId}');
    }
  }

  Future<void> _startPlayback() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _pc.playSceneId(widget.sceneId);
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString();
      });
      }
    } finally {
      if (mounted) {
        setState(() {
        _loading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext _) => Scaffold(
        appBar: AppBar(title: Text('Сцена ${widget.sceneId}')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ошибка: $_error', style: const TextStyle(color: Colors.red)),
              )
            else if (_loading)
              const CircularProgressIndicator()
            else if (kIsWeb)
              // On web show a user-triggered Play button to satisfy autoplay policies
              ElevatedButton.icon(
                onPressed: _startPlayback,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
              )
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(onPressed: _pc.back10, icon: const Icon(Icons.replay_10)),
                IconButton(onPressed: _pc.toggle, icon: const Icon(Icons.play_arrow)),
                IconButton(onPressed: _pc.fwd10, icon: const Icon(Icons.forward_10)),
              ]),
          ]),
        ),
      );
}
