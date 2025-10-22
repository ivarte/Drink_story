import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Правила и 18+')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('18+. Пейте ответственно. Не садитесь за руль. Наушники обязательны.'),
    ),
  );
}
