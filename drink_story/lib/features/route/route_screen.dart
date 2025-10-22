import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Маршрут: 4 бара')),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ElevatedButton(onPressed: ()=>context.go('/activate'), child: const Text('Активация')),
        const SizedBox(height:8),
        ElevatedButton(onPressed: ()=>context.go('/scan'), child: const Text('Сканировать QR')),
        const SizedBox(height:8),
        ElevatedButton(onPressed: ()=>context.go('/faq'), child: const Text('FAQ / 18+')),
      ])),
    );
  }
}
