import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

class RequestService {
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'token');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // --- GETTERS ---
  Future<List<dynamic>> getMyRequests() async {
    try {
      final res = await http.get(Uri.parse(ApiConstants.myRequestsEndpoint), headers: await _headers());
      return jsonDecode(res.body)['data'] ?? [];
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getReceivedRequests() async {
    try {
      final res = await http.get(Uri.parse(ApiConstants.receivedRequestsEndpoint), headers: await _headers());
      return jsonDecode(res.body)['data'] ?? [];
    } catch (e) { return []; }
  }

  // --- ACTIONS ---
  Future<Map<String, dynamic>> requestItem(int itemId) async {
    final res = await http.post(Uri.parse(ApiConstants.requestItemEndpoint(itemId)), headers: await _headers());
    final data = jsonDecode(res.body);
    return {'success': res.statusCode == 201, 'message': data['message'] ?? data['error']};
  }
  
  // --- NEW: Check if I already requested this item ---
  Future<bool> hasRequestedItem(int itemId) async {
    try {
      final token = await _storage.read(key: 'token');
      final res = await http.get(
        Uri.parse(ApiConstants.checkRequestStatusEndpoint(itemId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['hasRequested'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }


  Future<bool> proposeTime(int requestId, String dateTimeIso) async {
    final res = await http.put(Uri.parse('${ApiConstants.baseUrl}/requests/$requestId/propose'), headers: await _headers(), body: jsonEncode({'proposedTime': dateTimeIso}));
    return res.statusCode == 200;
  }

  Future<bool> acceptProposal(int requestId) async {
    final res = await http.put(Uri.parse('${ApiConstants.baseUrl}/requests/$requestId/accept-proposal'), headers: await _headers());
    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>> confirmHandshake(int requestId) async {
    final res = await http.put(Uri.parse('${ApiConstants.baseUrl}/requests/$requestId/confirm'), headers: await _headers());
    final data = jsonDecode(res.body);
    return {'success': res.statusCode == 200, 'message': data['message'] ?? data['error']};
  }

  Future<bool> cancelRequest(int requestId) async {
    final res = await http.put(Uri.parse(ApiConstants.cancelRequestEndpoint(requestId)), headers: await _headers());
    return res.statusCode == 200;
  }
}