import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  final _storage = const FlutterSecureStorage();

  // 1. Synchronous Constructor:
  // Receives the theme we already fetched in main.dart before the UI booted.
  // This completely eliminates the "White Flash" on startup!
  ThemeProvider(this._themeMode);

  ThemeMode get themeMode => _themeMode;

  // 2. The Toggle Action (Used by Settings Screen)
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Instantly paints the app
    
    // Saves to memory in the background
    await _storage.write(key: 'theme_mode', value: isDark ? 'dark' : 'light');
  }

  // 3. Reset to System Action (Optional: If you ever want to add a "System Default" button)
  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    notifyListeners();
    
    // Deletes the hard-saved lock so it follows the phone's settings again
    await _storage.delete(key: 'theme_mode'); 
  }
}