import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart'; // <-- IMPORT PROVIDER

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme_provider.dart'; // <-- IMPORT THEME PROVIDER
import '../../../services/auth_service.dart';
import '../../../services/api_client.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  
  // Local state for the switch
  bool _isDarkMode = false;

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sets the switch's initial position based on current active theme
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.error : AppColors.primary));
  }

  // --- THEME TOGGLE LOGIC (NOW USING PROVIDER) ---
  Future<void> _toggleTheme(bool isDark) async {
    setState(() => _isDarkMode = isDark);
    
    // Calls your ThemeProvider which instantly repaints the app AND saves it to memory!
    await Provider.of<ThemeProvider>(context, listen: false).toggleTheme(isDark);
  }

  // --- CHANGE PASSWORD FLOW ---
  void _openChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Confirm your Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_emailController.text.isEmpty || _newPasswordController.text.isEmpty) {
                    _showToast('Fill all fields', isError: true);
                    return;
                  }
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  final response = await _authService.resetPassword(_emailController.text.trim(), _newPasswordController.text.trim());
                  setState(() => _isLoading = false);
                  _showToast(response.message, isError: !response.success);
                  _emailController.clear();
                  _newPasswordController.clear();
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AppColors.primary),
                child: const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // --- DELETE ACCOUNT FLOW ---
  void _openDeleteAccountModal() {
    TextEditingController confirmController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account?'),
        content: Column(
          children: [
            const SizedBox(height: 10),
            const Text('This action is irreversible. All your items and requests will be deleted. Type "DELETE" below to confirm.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: confirmController,
              placeholder: 'Type DELETE',
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel', style: TextStyle(color: Colors.blue)), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              if (confirmController.text.trim().toUpperCase() != 'DELETE') {
                _showToast('You must type DELETE exactly', isError: true);
                return;
              }
              Navigator.pop(context); 
              
              setState(() => _isLoading = true);
              final response = await ApiClient.delete('${ApiConstants.baseUrl}/users/me');
              
              if (response.statusCode == 200 || response.statusCode == 204) {
                await _storage.deleteAll();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                }
              } else {
                setState(() => _isLoading = false);
                _showToast('Failed to delete account.', isError: true);
              }
            },
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );
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
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
        leading: IconButton(icon: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                
                // --- PREFERENCES SECTION ---
                Text('PREFERENCES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.textMutedDark : Colors.grey[600], letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(CupertinoIcons.moon_stars_fill, color: isDark ? Colors.amber : Colors.blueGrey),
                    title: Text('Dark Mode', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                    trailing: CupertinoSwitch(
                      activeColor: AppColors.primary,
                      value: _isDarkMode,
                      onChanged: _toggleTheme,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // --- SECURITY SECTION ---
                Text('SECURITY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.textMutedDark : Colors.grey[600], letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(CupertinoIcons.lock_fill, color: AppColors.primary),
                    title: Text('Change Password', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.grey),
                    onTap: _openChangePasswordSheet,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // --- DANGER ZONE ---
                Text('DANGER ZONE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(CupertinoIcons.trash_fill, color: AppColors.error),
                    title: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    onTap: _openDeleteAccountModal,
                  ),
                ),
              ],
            ),
    );
  }
}