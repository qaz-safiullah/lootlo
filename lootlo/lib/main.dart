import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // <-- Added to read memory on boot

import 'core/globals.dart';
import 'core/app_theme.dart';
import 'core/theme_provider.dart';
import 'features/auth/screens/auth_wrapper.dart';

void main() async {
  // 1. Ensure widgets are bound before reading from native storage
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Read saved theme from secure memory BEFORE booting the UI
  const storage = FlutterSecureStorage();
  final savedTheme = await storage.read(key: 'theme_mode');
  
  ThemeMode initialTheme = ThemeMode.system;
  if (savedTheme == 'dark') {
    initialTheme = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    initialTheme = ThemeMode.light;
  }

  runApp(
    // 3. Inject the initial theme into the Provider
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(initialTheme), 
      child: const LootloApp(),
    ),
  );
}

class LootloApp extends StatelessWidget {
  const LootloApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Now it safely finds the provider and listens to all future changes
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Lootlo',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode, 
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      home: const AuthWrapper(),
    );
  }
}