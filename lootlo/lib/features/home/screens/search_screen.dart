import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/item_service.dart';
import '../../giveaway/screens/item_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ItemService _itemService = ItemService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false; // To show "Type something" vs "No results"
  
  String _selectedCategory = 'All';
  double _userLat = 24.8607;
  double _userLng = 67.0011;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    } catch (e) {
      // Fallback to default if location fails
    }
  }

  // --- THE SEARCH ENGINE ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Wait 800ms after the user stops typing before hitting the backend
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (query.trim().isNotEmpty || _selectedCategory != 'All') {
        _performSearch();
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final results = await _itemService.getNearbyItems(
      lat: _userLat,
      lng: _userLng,
      keyword: _searchController.text.trim(),
      category: _selectedCategory,
      radius: 50, // Let them search a wider radius of 50km
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(20)),
            child: TextField(
              controller: _searchController,
              autofocus: true, // Pops keyboard instantly!
              onChanged: _onSearchChanged,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search for laptops, bikes...',
                hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 14),
                prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.primary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_thick_circled, color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: _buildCategoriesList(isDark),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : !_hasSearched
              ? _buildStartState(isDark)
              : _searchResults.isEmpty
                  ? _buildEmptyState(isDark)
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.70,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) => _buildLiveCard(_searchResults[index], isDark),
                    ),
    );
  }

  Widget _buildCategoriesList(bool isDark) {
    return Container(
      height: 50,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight))),
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
                _performSearch();
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

  Widget _buildStartState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, size: 80, color: isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('What are you looking for?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('Search by name or select a category', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use search_circle or just the standard search icon for a cleaner look
          Icon(CupertinoIcons.search_circle, size: 80, color: isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No exact matches found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('Try broader terms or a different category.', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ],
      ),
    );
  }

  Widget _buildLiveCard(dynamic item, bool isDark) {
    String imageUrl = _parseImageUrl(item['main_image']);
    double distance = double.tryParse(item['distance']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item)));
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
              child: Container(
                width: double.infinity,
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.photo, color: Colors.grey))
                    : const Icon(CupertinoIcons.photo, color: Colors.grey),
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