import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

class WishlistService {
  final _storage = const FlutterSecureStorage();

  Future<bool> checkWishlist(int itemId) async {
    try {
      final token = await _storage.read(key: 'token');
      final res = await http.get(
        Uri.parse(ApiConstants.checkWishlistEndpoint(itemId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['inWishlist'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleWishlist(int itemId) async {
    try {
      final token = await _storage.read(key: 'token');
      final res = await http.post(
        Uri.parse(ApiConstants.toggleWishlistEndpoint(itemId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  // --- NEW: Get all saved items ---
  Future<List<dynamic>> getMyWishlist() async {
    try {
      final token = await _storage.read(key: 'token');
      final res = await http.get(
        Uri.parse(ApiConstants.wishlistEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}