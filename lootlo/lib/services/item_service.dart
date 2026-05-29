import 'dart:io';
import 'dart:convert'; // <-- ADDED: Crucial for JSON encoding/decoding!
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

class ItemService {
  final _storage = const FlutterSecureStorage();

  // 1. CREATE ITEM (Multipart with Images)
  Future<bool> createItem({
    required String title,
    required String description,
    required String category,
    required String city,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    required List<File> images,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      
      var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.itemsEndpoint));
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Attach all text data
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['category'] = category;
      request.fields['city'] = city;
      request.fields['address'] = address;
      request.fields['phone'] = phone;
      request.fields['lat'] = lat.toString();
      request.fields['lng'] = lng.toString();
      request.fields['status'] = 'available';

      // Attach all images
      for (var image in images) {
        request.files.add(await http.MultipartFile.fromPath('images', image.path)); 
      }

      var response = await request.send();
      
      if (response.statusCode == 201) {
        return true;
      } else {
        print('Upload failed: ${await response.stream.bytesToString()}');
        return false;
      }
    } catch (e) {
      print('Network error: $e');
      return false;
    }
  }

  // 2. GET MY LISTINGS
  Future<List<dynamic>> getMyListings() async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse(ApiConstants.myListingsEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; 
      }
      return [];
    } catch (e) {
      print('Error fetching my listings: $e');
      return [];
    }
  }

// 3. UPDATE ITEM (Edit Listing + Images)
  Future<bool> updateItem({
    required int itemId,
    required String title,
    required String description,
    required String category,
    required String city,
    required String address,
    required String phone,
    required List<String> retainedImages, // The old URLs they kept
    required List<File> newImages,        // The brand new photos
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      
      // CRITICAL: We use MultipartRequest with a 'PUT' method!
      var request = http.MultipartRequest('PUT', Uri.parse(ApiConstants.itemDetailsEndpoint(itemId)));
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Attach text fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['category'] = category;
      request.fields['city'] = city;
      request.fields['address'] = address;
      request.fields['phone'] = phone;
      
      // Pass the retained database paths to the backend
      request.fields['retained_images'] = jsonEncode(retainedImages);

      // Attach new files
      for (var image in newImages) {
        request.files.add(await http.MultipartFile.fromPath('images', image.path)); 
      }

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Network error updating item: $e');
      return false;
    }
  }
  // 4. DELETE ITEM
  Future<bool> deleteItem(int itemId) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.delete(
        Uri.parse(ApiConstants.itemDetailsEndpoint(itemId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

// --- UPGRADED: Fetch Nearby Items (Now with Search Engine power!) ---
  Future<List<dynamic>> getNearbyItems({
    required double lat,
    required double lng,
    String category = 'All',
    String keyword = '',    // <-- Added Keyword
    int radius = 20,        // <-- Added Radius
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      
      // Build the advanced query URL
      String url = '${ApiConstants.nearbyItemsEndpoint}?lat=$lat&lng=$lng&radius=$radius';
      if (category != 'All') url += '&category=$category';
      if (keyword.isNotEmpty) url += '&keyword=$keyword';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; 
      }
      return [];
    } catch (e) {
      print('Error fetching nearby items: $e');
      return [];
    }
  }  
}