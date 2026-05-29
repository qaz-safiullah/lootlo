import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/wishlist_service.dart';
import 'item_details_screen.dart';

class MyWishlistScreen extends StatefulWidget {
  const MyWishlistScreen({super.key});

  @override
  State<MyWishlistScreen> createState() => _MyWishlistScreenState();
}

class _MyWishlistScreenState extends State<MyWishlistScreen> {
  final WishlistService _wishlistService = WishlistService();
  List<dynamic> _wishlistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    setState(() => _isLoading = true);
    final items = await _wishlistService.getMyWishlist();
    if (mounted) {
      setState(() {
        _wishlistItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(int itemId) async {
    // Optimistic UI Removal
    setState(() {
      _wishlistItems.removeWhere((item) => item['id'] == itemId);
    });
    
    // Background Sync
    await _wishlistService.toggleWishlist(itemId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from wishlist'), duration: Duration(seconds: 1))
    );
  }

  String _parseImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    String cleanBase = ApiConstants.baseUrl.replaceAll('/api', '');
    String cleanPath = url.replaceAll('\\', '/');
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('My Wishlist', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _wishlistItems.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchWishlist,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _wishlistItems.length,
                    itemBuilder: (context, index) => _buildWishlistCard(_wishlistItems[index], isDark),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.heart_slash, size: 80, color: isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No Saved Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('Items you heart will appear here.', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(dynamic item, bool isDark) {
    String imageUrl = _parseImageUrl(item['main_image']);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item))).then((_) => _fetchWishlist()); // Refresh on return
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 120, height: 120,
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : const Icon(CupertinoIcons.photo, color: Colors.grey),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? 'No Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('By: ${item['giver_name']}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text('${item['community_score'] ?? 0} Score', style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.heart_fill, color: Colors.redAccent),
              onPressed: () => _removeFromWishlist(item['id']),
            ),
          ],
        ),
      ),
    );
  }
}