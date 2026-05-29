import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isPasswordHidden = true;

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    AuthResponse response = await _authService.signup(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response.success && mounted) {
      _showToast('Account Created! Routing to Home...');
      // Navigation will go here later
    } else if (mounted) {
      _showToast(response.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the movement and start saving today.',
                  style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 16),
                ),
                const SizedBox(height: 40),

                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  isDark: isDark,
                  validator: (value) => value!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  validator: (value) => value!.isEmpty ? 'Email is required' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  obscureText: _isPasswordHidden,
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                  ),
                  validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        prefixIcon: Icon(icon, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}