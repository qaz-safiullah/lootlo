import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/item_service.dart';
import '../../../services/wishlist_service.dart'; 
import '../../giveaway/screens/item_details_screen.dart';
import 'search_screen.dart'; 

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final ItemService _itemService = ItemService();
  final WishlistService _wishlistService = WishlistService();
  
  String _selectedCategory = 'All';
  String _selectedCity = 'Locating...'; 
  
  List<dynamic> _feedItems = [];
  Set<int> _savedItemIds = {}; 
  
  bool _isLoading = true;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _initializeFeed();
  }

  Future<void> _initializeFeed() async {
    // We don't set _isLoading = true here to avoid flickering on refresh
    _wishlistService.getMyWishlist().then((items) {
      if (mounted) {
        setState(() {
          _savedItemIds = items.map<int>((i) => i['id'] as int).toSet();
        });
      }
    });

    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _userLat = pos.latitude;
      _userLng = pos.longitude;
      setState(() => _selectedCity = 'Nearby'); 
      await _fetchData();
    } catch (e) {
      _userLat = 24.8607;
      _userLng = 67.0011;
      setState(() => _selectedCity = 'Karachi');
      await _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (_userLat == null || _userLng == null) return;
    
    // Only show loader if we aren't already loading
    if (!_isLoading) setState(() => _isLoading = true);
    
    final items = await _itemService.getNearbyItems(
      lat: _userLat!, 
      lng: _userLng!, 
      category: _selectedCategory
    );
    
    if (mounted) {
      setState(() {
        _feedItems = items;
        _isLoading = false;
      });
    }
  }

  // --- OPTIMISTIC HEART TOGGLE ---
  Future<void> _toggleHeart(int itemId) async {
    setState(() {
      if (_savedItemIds.contains(itemId)) {
        _savedItemIds.remove(itemId);
      } else {
        _savedItemIds.add(itemId);
      }
    });

    bool success = await _wishlistService.toggleWishlist(itemId);
    
    if (!success && mounted) {
      setState(() {
        if (_savedItemIds.contains(itemId)) {
          _savedItemIds.remove(itemId);
        } else {
          _savedItemIds.add(itemId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error syncing wishlist.')));
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchData, // Trigger the refresh!
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            floating: true,
            pinned: true,
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            elevation: 0,
            leading: IconButton(
              icon: Icon(CupertinoIcons.bars, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.location_solid, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(_selectedCity, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildSearchBar(isDark),
                  const SizedBox(height: 50), 
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50.0),
              child: _buildCategoriesList(isDark),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_feedItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.search, size: 60, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No items found nearby', style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.70, 
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildLiveCard(_feedItems[index], isDark); 
                  },
                  childCount: _feedItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0, right: 12.0),
                child: Icon(CupertinoIcons.search, color: AppColors.primary, size: 20),
              ),
              Text('Search for laptops, bikes...', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: AppConstants.categories.length,
        itemBuilder: (context, index) {
          final category = AppConstants.categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
                _fetchData(); 
              },
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveCard(dynamic item, bool isDark) {
    String imageUrl = _parseImageUrl(item['main_image']);
    double distance = double.tryParse(item['distance']?.toString() ?? '0') ?? 0;
    bool isSaved = _savedItemIds.contains(item['id']);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item))).then((_) => _initializeFeed());
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.photo, color: Colors.grey))
                        : const Icon(CupertinoIcons.photo, color: Colors.grey),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleHeart(item['id']),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                        child: Icon(isSaved ? CupertinoIcons.heart_fill : CupertinoIcons.heart, color: isSaved ? Colors.redAccent : Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['title'] ?? '', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.person_solid, color: AppColors.primary, size: 12),
                        const SizedBox(width: 4),
                        Expanded(child: Text(item['giver_name'] ?? 'User', style: TextStyle(color: isDark ? AppColors.textMutedDark : Colors.grey[700], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Text('${item['community_score'] ?? 0}', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}