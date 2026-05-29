import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../giveaway/screens/add_item_screen.dart';
import 'home_feed_screen.dart';
import '../../giveaway/screens/my_listings_screen.dart';
import '../../giveaway/screens/my_requests_screen.dart';
import '../../giveaway/screens/my_wishlist_screen.dart';
import '../../profile/screens/profile_screen.dart'; // <-- IMPORTED PROFILE
import '../../profile/screens/settings_screen.dart'; // <-- IMPORTED SETTINGS

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  String _userName = "Loading...";
  String _userScore = "...";

  // The fully realized bottom nav screens!
  final List<Widget> _screens = [
    const HomeFeedScreen(),
    const MyListingsScreen(),
    const MyRequestsScreen(),
    const ProfileScreen(), // <-- REPLACED PLACEHOLDER
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: 'name');
    final token = await storage.read(key: 'token');

    if (mounted) {
      setState(() => _userName = name ?? "Lootlo User");
    }

    if (token != null) {
      try {
        final response = await http.get(Uri.parse(ApiConstants.profileEndpoint), headers: {'Authorization': 'Bearer $token'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              var fetchedScore = data['community_score'] ?? data['user']?['community_score'] ?? data['data']?['community_score'] ?? "0";
              var fetchedName = data['name'] ?? data['user']?['name'] ?? data['data']?['name'] ?? _userName;
              _userScore = fetchedScore.toString();
              _userName = fetchedName.toString();
            });
          }
        } else {
          if (mounted) setState(() => _userScore = "0");
        }
      } catch (e) {
        if (mounted) setState(() => _userScore = "0");
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: _buildPremiumDrawer(isDark),
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen())),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: CupertinoIcons.home, label: 'Home', index: 0, isDark: isDark),
              _buildNavItem(icon: CupertinoIcons.list_bullet, label: 'My Listings', index: 1, isDark: isDark),
              const SizedBox(width: 40),
              _buildNavItem(icon: CupertinoIcons.hand_draw, label: 'My Requests', index: 2, isDark: isDark),
              _buildNavItem(icon: CupertinoIcons.person, label: 'Profile', index: 3, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required bool isDark}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPremiumDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.primary.withOpacity(0.1)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'L', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            accountName: Text(_userName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('🏆 Community Score: $_userScore', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
          ListTile(
            leading: Icon(CupertinoIcons.heart, color: isDark ? Colors.white : Colors.black),
            title: const Text('My Wishlist'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyWishlistScreen()));
            },
          ),
          ListTile(
            leading: Icon(CupertinoIcons.settings, color: isDark ? Colors.white : Colors.black),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())); // <-- WIRED UP!
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(CupertinoIcons.square_arrow_left, color: AppColors.error),
            title: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}