import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

// Ensure you have a core/globals.dart file defining: final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
import '../core/globals.dart'; 
import '../features/auth/screens/login_screen.dart'; // Un-commented!

class ApiClient {
  static const _storage = FlutterSecureStorage();

  // Automatically injects the JWT token into every request
  static Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- GLOBAL SESSION KICK-OUT ---
  static Future<void> _handleUnauthorized() async {
    await _storage.deleteAll(); // Wipe the dead token & user data
    
    // Uses the global navigatorKey to route the user even if they are deep inside the app
    if (navigatorKey.currentContext != null) {
      Navigator.pushAndRemoveUntil(
        navigatorKey.currentContext!,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Wrapper for GET requests
  static Future<http.Response> get(String url) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 401) await _handleUnauthorized();
    return response;
  }

  // Wrapper for POST requests
  static Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
    if (response.statusCode == 401) await _handleUnauthorized();
    return response;
  }

  // Wrapper for PUT requests
  static Future<http.Response> put(String url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(Uri.parse(url), headers: headers, body: jsonEncode(body));
    if (response.statusCode == 401) await _handleUnauthorized();
    return response;
  }

  // Wrapper for DELETE requests
  static Future<http.Response> delete(String url) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse(url), headers: headers);
    if (response.statusCode == 401) await _handleUnauthorized();
    return response;
  }
}