import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gecmis')),
      body: const Center(child: Text('Gecmis arastirmalariniz.')),
    );
  }
}
