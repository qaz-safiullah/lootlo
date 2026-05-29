import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../home/screens/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    AuthResponse response = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response.success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
        (route) => false,
      );
    }
     else if (mounted) {
      _showToast(response.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(child: Image.asset('assets/images/logo.png', height: 90)),
                const SizedBox(height: 60),
                
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your details to proceed.',
                  style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 16),
                ),
                const SizedBox(height: 40),
                
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
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
                  validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
  child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Log In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('New to Lootlo?', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                      child: const Text('Create Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // A helper method to keep our inputs perfectly styled for OLED Dark Mode
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