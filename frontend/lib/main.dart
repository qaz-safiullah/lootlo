import 'package:flutter/material.dart';

void main() {
  runApp(const LootloApp());
}

class LootloApp extends StatelessWidget {
  const LootloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lootlo',
      debugShowCheckedModeBanner: false,
      
      // Defining our sleek, luxury green theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF064E3B), // Deep Emerald Green
          primary: const Color(0xFF064E3B),
          secondary: const Color(0xFF10B981), // Vibrant Mint Accent
          background: const Color(0xFFF9FAFB), // Off-white clean canvas
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF064E3B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF064E3B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Quick Placeholder Splash Screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF064E3B), // Premium Green background
      body: Center(
        child: Text(
          'LOOTLOOOO',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}