// lib/main.dart
import 'package:flutter/material.dart';
import 'package:assistant/pages/home_page.dart';

void main() {
  runApp(const CommandClassifierApp());
}

class CommandClassifierApp extends StatelessWidget {
  const CommandClassifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Command Classifier',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
