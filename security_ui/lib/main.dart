import 'package:flutter/material.dart';
import 'presentation/screens/welcome_screen.dart';

void main() {
  runApp(const SecurityMonitorApp());
}

class SecurityMonitorApp extends StatelessWidget {
  const SecurityMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F1C),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.cyanAccent,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
