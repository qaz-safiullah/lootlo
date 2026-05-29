import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

class AuthResponse {
  final bool success;
  final String message;

  AuthResponse({required this.success, required this.message});
}

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Helper to extract the exact error from our Node backend
  String _extractError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['error'] ?? 'An unknown error occurred';
    } catch (_) {
      return 'Server error. Please try again later.';
    }
  }

  Future<AuthResponse> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.signupEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'token', value: data['token']);
        // CRITICAL FIX: Saved as 'user_id' so ItemDetailsScreen recognizes the owner!
        await _storage.write(key: 'user_id', value: data['user']['id'].toString());
        await _storage.write(key: 'name', value: data['user']['name']);
        
        return AuthResponse(success: true, message: 'Signup successful');
      } else {
        return AuthResponse(success: false, message: _extractError(response));
      }
    } catch (e) {
      return AuthResponse(success: false, message: 'Network error. Check connection.');
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'token', value: data['token']);
        // CRITICAL FIX: Saved as 'user_id'
        await _storage.write(key: 'user_id', value: data['user']['id'].toString());
        await _storage.write(key: 'name', value: data['user']['name']);
        
        return AuthResponse(success: true, message: 'Login successful');
      } else {
        return AuthResponse(success: false, message: _extractError(response));
      }
    } catch (e) {
      return AuthResponse(success: false, message: 'Network error. Check connection.');
    }
  }

  Future<AuthResponse> resetPassword(String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.resetPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        return AuthResponse(success: true, message: 'Password reset successfully!');
      } else {
        return AuthResponse(success: false, message: _extractError(response));
      }
    } catch (e) {
      return AuthResponse(success: false, message: 'Network error. Check connection.');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}