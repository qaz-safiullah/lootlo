import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/item_service.dart';
import '../../../core/constants/api_constants.dart';
import 'add_item_screen.dart'; 

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final ItemService _itemService = ItemService();
  List<dynamic> _myItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyItems();
  }

  Future<void> _fetchMyItems() async {
    setState(() => _isLoading = true);
    final items = await _itemService.getMyListings();
    if (mounted) {
      setState(() {
        _myItems = items;
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(int itemId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Giveaway?'),
        content: const Text('This will permanently remove the item and its images from the platform.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context); 
              setState(() => _isLoading = true);
              bool success = await _itemService.deleteItem(itemId);
              if (success) {
                _fetchMyItems(); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted successfully.'), backgroundColor: AppColors.primary));
              } else {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete item.'), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _routeToFullEdit(dynamic item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(existingItem: item),
      ),
    );
    _fetchMyItems(); // Refreshes the list when returning from the edit screen!
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
        title: Text('My Listings', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
        
        leading: IconButton(
          icon: Icon(CupertinoIcons.bars, color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            Scaffold.of(context).openDrawer(); 
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _myItems.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchMyItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
                    itemCount: _myItems.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(_myItems[index], isDark);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.cube_box, size: 80, color: isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No Listings Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('Items you give away will appear here.', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item, bool isDark) {
    String imageUrl = item['main_image'] ?? ''; 
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      String cleanBase = ApiConstants.baseUrl.replaceAll('/api', '');
      String cleanPath = imageUrl.replaceAll('\\', '/');
      if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
      imageUrl = '$cleanBase$cleanPath';
    }

    String status = item['status']?.toLowerCase() ?? 'available';
    Color statusColor = AppColors.primary;
    
    String displayStatus = 'AVAILABLE';
    if (status == 'promised') {
      statusColor = Colors.orange;
      displayStatus = 'PROMISED';
    } else if (status == 'completed') {
      statusColor = Colors.blue;
      displayStatus = 'GIVEN AWAY';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  border: Border(right: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.photo, color: Colors.grey))
                    : const Icon(CupertinoIcons.photo, color: Colors.grey),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'No Title', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['description'] ?? '', 
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.circle_fill, size: 10, color: statusColor),
                            const SizedBox(width: 6),
                            Text(displayStatus, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          
          // perfectly balanced 2-button layout
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _routeToFullEdit(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.pencil, size: 18, color: isDark ? Colors.white : Colors.black),
                        const SizedBox(width: 6),
                        Text('Edit Listing', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: isDark ? AppColors.borderDark : AppColors.borderLight),
              Expanded(
                child: InkWell(
                  onTap: () => _confirmDelete(item['id']),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.trash, size: 18, color: AppColors.error),
                        SizedBox(width: 6),
                        Text('Delete', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}