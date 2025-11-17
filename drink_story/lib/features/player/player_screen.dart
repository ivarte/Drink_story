import 'package:flutter/material.dart';
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
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _pc.playSceneId(widget.sceneId).then((_) {
      if (mounted) setState(() => _loaded = true);
    }).catchError((e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loaded = false;
      });
    });
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
            else if (!_loaded)
              const CircularProgressIndicator()
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
