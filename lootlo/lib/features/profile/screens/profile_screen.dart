import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/request_service.dart';
import '../../../services/wishlist_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../giveaway/screens/my_requests_screen.dart';
import '../../giveaway/screens/my_wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String _communityScore = "0";

  int _wishlistCount = 0;
  int _itemsGivenCount = 0;
  int _itemsTakenCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfileStats();
  }

  // --- CONCURRENT DATA ENGINE ---
  Future<void> _fetchProfileStats() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return;

      // Fire all 4 API calls simultaneously for massive speed!
      final results = await Future.wait([
        http.get(Uri.parse(ApiConstants.profileEndpoint), headers: {'Authorization': 'Bearer $token'}),
        WishlistService().getMyWishlist(),
        RequestService().getReceivedRequests(), // Items I am Giving
        RequestService().getMyRequests(),       // Items I am Taking
      ]);

      final profileRes = results[0] as http.Response;
      final wishlist = results[1] as List<dynamic>;
      final receivedReqs = results[2] as List<dynamic>;
      final sentReqs = results[3] as List<dynamic>;

      // 1. Parse Profile
      if (profileRes.statusCode == 200) {
        final data = jsonDecode(profileRes.body);
        _communityScore = (data['community_score'] ?? data['user']?['community_score'] ?? data['data']?['community_score'] ?? "0").toString();
        _userName = (data['name'] ?? data['user']?['name'] ?? data['data']?['name'] ?? "Lootlo User").toString();
        _userEmail = (data['email'] ?? data['user']?['email'] ?? data['data']?['email'] ?? "No email provided").toString();
      }

      // 2. Calculate Actual Transaction Stats
      _wishlistCount = wishlist.length;
      
      // Items Given = Received Requests where the status is 'completed'
      _itemsGivenCount = receivedReqs.where((req) => req['request_status'] == 'completed').length;
      
      // Items Taken = Sent Requests where the status is 'completed'
      _itemsTakenCount = sentReqs.where((req) => req['request_status'] == 'completed').length;

    } catch (e) {
      debugPrint("Error fetching profile stats: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
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
        title: Text('My Profile', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
        leading: IconButton(
          icon: Icon(CupertinoIcons.bars, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchProfileStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100), // Space for nav bar
                child: Column(
                  children: [
                    // --- HEADER SECTION ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'L', 
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary)
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(_userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                          const SizedBox(height: 4),
                          Text(_userEmail, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : Colors.grey[600])),
                          const SizedBox(height: 20),
                          
                          // Big Trust Score Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade500]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.star_fill, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text('Community Score: $_communityScore', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // --- INTERACTIVE STATS GRID ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              _buildStatCard(
                                title: 'Wishlist',
                                count: _wishlistCount.toString(),
                                icon: CupertinoIcons.heart_fill,
                                color: Colors.redAccent,
                                isDark: isDark,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyWishlistScreen())),
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                title: 'Items Taken',
                                count: _itemsTakenCount.toString(),
                                icon: CupertinoIcons.bag_fill,
                                color: Colors.blue,
                                isDark: isDark,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRequestsScreen(initialIndex: 0))), // 0 = Sent (Taking)
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStatCard(
                                title: 'Items Given',
                                count: _itemsGivenCount.toString(),
                                icon: CupertinoIcons.gift_fill,
                                color: Colors.green,
                                isDark: isDark,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRequestsScreen(initialIndex: 1))), // 1 = Received (Giving)
                              ),
                              const SizedBox(width: 16),
                              // Empty placeholder to balance the grid
                              Expanded(child: Container()), 
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- ACTIONS ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(CupertinoIcons.square_arrow_left, color: Colors.white),
                        label: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- STAT CARD WIDGET ---
  Widget _buildStatCard({required String title, required String count, required IconData icon, required Color color, required bool isDark, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? AppColors.borderDark : Colors.transparent),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textMutedDark : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}