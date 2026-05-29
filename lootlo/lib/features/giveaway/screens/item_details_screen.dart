import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';       
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/request_service.dart'; 
import '../../../services/wishlist_service.dart'; // NEW: Wishlist Service

class ItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final RequestService _requestService = RequestService();
  final WishlistService _wishlistService = WishlistService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isRequesting = false;
  bool _isLoadingState = true;
  
  // UX Flags
  bool _isMyOwnItem = false;
  bool _alreadyRequested = false;
  bool _isInWishlist = false;

  // Image Carousel State
  int _currentImageIndex = 0;
  List<String> _galleryImages = [];

  @override
  void initState() {
    super.initState();
    _extractImages();
    _checkItemState();
  }

  // --- EXTRACT MULTIPLE IMAGES ---
  void _extractImages() {
    List<String> images = [];
    
    // If your backend feeds an array of 'images'
    if (widget.item['images'] != null && widget.item['images'] is List) {
      for (var img in widget.item['images']) {
        String url = img is String ? img : (img['image_url'] ?? '');
        if (url.isNotEmpty) images.add(_parseImageUrl(url));
      }
    } 
    // Fallback to main_image if array doesn't exist
    else if (widget.item['main_image'] != null && widget.item['main_image'].toString().isNotEmpty) {
      images.add(_parseImageUrl(widget.item['main_image']));
    }
    
    setState(() => _galleryImages = images);
  }

  // --- INTELLIGENCE ENGINE ---
  Future<void> _checkItemState() async {
    String? myIdString = await _storage.read(key: 'user_id'); 
    int myId = int.tryParse(myIdString ?? '0') ?? 0;
    int itemOwnerId = int.tryParse(widget.item['user_id']?.toString() ?? '0') ?? 0;
    int itemId = widget.item['id'];

    if (myId != 0 && myId == itemOwnerId) {
      if (mounted) setState(() { _isMyOwnItem = true; _isLoadingState = false; });
      return; 
    }

    // Run Wishlist & Request checks in parallel for speed!
    final results = await Future.wait([
      _requestService.hasRequestedItem(itemId),
      _wishlistService.checkWishlist(itemId),
    ]);
    
    if (mounted) {
      setState(() {
        _alreadyRequested = results[0];
        _isInWishlist = results[1];
        _isLoadingState = false;
      });
    }
  }

  // --- WISHLIST TOGGLE LOGIC ---
  Future<void> _toggleWishlist() async {
    // Optimistic UI update (feels instantly responsive)
    setState(() => _isInWishlist = !_isInWishlist);
    
    bool success = await _wishlistService.toggleWishlist(widget.item['id']);
    
    if (!success && mounted) {
      // Revert if backend fails
      setState(() => _isInWishlist = !_isInWishlist);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update wishlist.')));
    }
  }

  String _parseImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    String cleanBase = ApiConstants.baseUrl.replaceAll('/api', '');
    String cleanPath = url.replaceAll('\\', '/');
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
    return '$cleanBase$cleanPath';
  }

  // --- FULL SCREEN IMAGE VIEWER ---
  void _openFullScreenViewer(int initialIndex) {
    if (_galleryImages.isEmpty) return;
    
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: PageView.builder(
          itemCount: _galleryImages.length,
          controller: PageController(initialPage: initialIndex),
          itemBuilder: (context, index) {
            return InteractiveViewer( // Enables Pinch-to-Zoom!
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(_galleryImages[index], fit: BoxFit.contain),
            );
          },
        ),
      ),
    ));
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please manually dial the number below.')));
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    try {
      final Uri launchUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng?q=$lat,$lng');
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use the inline map provided.')));
    }
  }

  Future<void> _handleRequestLoot() async {
    setState(() => _isRequesting = true);
    final result = await _requestService.requestItem(widget.item['id']);
    setState(() => _isRequesting = false);

    if (result['success'] && mounted) {
      setState(() => _alreadyRequested = true); 
      
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Request Sent! 🎉'),
          content: const Text('The giver has been notified. Check your "My Requests" tab for updates.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Awesome', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to send request.'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;
    
    double lat = double.tryParse(item['lat']?.toString() ?? '24.8607') ?? 24.8607;
    double lng = double.tryParse(item['lng']?.toString() ?? '67.0011') ?? 67.0011;
    LatLng itemLocation = LatLng(lat, lng);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F9FA),
      body: CustomScrollView(
        slivers: [
          // 1. Interactive Swipeable Image Header
          SliverAppBar(
            expandedHeight: 380.0,
            pinned: true,
            backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
            iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
            
            // Glassmorphism Wishlist Button
            actions: [
              if (!_isLoadingState && !_isMyOwnItem)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.3),
                    child: IconButton(
                      icon: Icon(
                        _isInWishlist ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        color: _isInWishlist ? Colors.redAccent : Colors.white,
                        size: 22,
                      ),
                      onPressed: _toggleWishlist,
                    ),
                  ),
                ),
            ],
            
            flexibleSpace: FlexibleSpaceBar(
              background: _galleryImages.isEmpty
                  ? Container(color: isDark ? Colors.grey[900] : Colors.grey[200], child: const Icon(CupertinoIcons.photo, size: 50, color: Colors.grey))
                  : Stack(
                      children: [
                        // The Swipeable Carousel
                        PageView.builder(
                          itemCount: _galleryImages.length,
                          onPageChanged: (index) => setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _openFullScreenViewer(index),
                              child: Hero(
                                tag: index == 0 ? 'item_${item['id']}' : 'item_img_$index', 
                                child: Image.network(_galleryImages[index], fit: BoxFit.cover),
                              ),
                            );
                          },
                        ),
                        
                        // Dark Gradient at bottom for text visibility
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                              ),
                            ),
                          ),
                        ),

                        // Carousel Dot Indicators
                        if (_galleryImages.length > 1)
                          Positioned(
                            bottom: 16, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_galleryImages.length, (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 10 : 6,
                                height: _currentImageIndex == index ? 10 : 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index ? AppColors.primary : Colors.white.withOpacity(0.5),
                                ),
                              )),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // 2. Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(item['title'] ?? 'No Title', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, height: 1.2))),
                      Container(
                        margin: const EdgeInsets.only(left: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(item['category'] ?? 'General', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text((item['giver_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Given by', style: TextStyle(color: isDark ? AppColors.textMutedDark : Colors.grey[600], fontSize: 12)),
                              Text(item['giver_name'] ?? 'Unknown User', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Trust Score', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text('${item['community_score'] ?? 0}', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  Text(item['description'] ?? 'No description provided.', style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.5)),
                  const SizedBox(height: 24),

                  Text('Pickup Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(CupertinoIcons.location_solid, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item['address'] ?? 'Address hidden', style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[300] : Colors.black))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (item['phone'] != null && item['phone'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.phone_circle_fill, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['phone'], 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: isDark ? Colors.white : Colors.black)
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IgnorePointer( 
                      ignoring: false, 
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: itemLocation,
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate), 
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.lootlo.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: itemLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_pin, color: AppColors.primary, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      if (item['phone'] != null && item['phone'].toString().isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(item['phone']),
                            icon: const Icon(CupertinoIcons.phone_fill, color: Colors.white, size: 18),
                            label: const Text('Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (item['phone'] != null && item['phone'].toString().isNotEmpty)
                        const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openMaps(lat, lng),
                          icon: const Icon(CupertinoIcons.map_fill, color: Colors.white, size: 18),
                          label: const Text('Directions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
        ],
      ),
      
      // --- THE INTELLIGENT STICKY BUTTON ---
      bottomNavigationBar: _isLoadingState 
        ? null 
        : _isMyOwnItem
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              color: isDark ? AppColors.backgroundDark : Colors.white,
              child: const Text('This is your own listing.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
            )
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.white,
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: ElevatedButton(
                onPressed: (_isRequesting || _alreadyRequested) ? null : _handleRequestLoot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alreadyRequested ? Colors.orange : AppColors.primary,
                  disabledBackgroundColor: _alreadyRequested ? Colors.orange.withOpacity(0.8) : Colors.grey[400],
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isRequesting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text(
                        _alreadyRequested ? 'ALREADY REQUESTED' : 'REQUEST LOOT', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)
                      ),
              ),
            ),
    );
  }
}