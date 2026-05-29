import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/screens/main_layout.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      // We built this function earlier in auth_service.dart!
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        // While the app is digging into secure storage, show a loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // If the token exists, boom -> Home Feed. Otherwise -> Login.
        if (snapshot.hasData && snapshot.data == true) {
          return const MainLayout();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}