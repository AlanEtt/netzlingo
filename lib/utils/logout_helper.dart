import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

class LogoutHelper {
  /// Menangani proses logout dengan pendekatan yang handal untuk menghindari UI yang stuck
  static Future<void> performLogout(
      BuildContext context, AuthProvider authProvider,
      {bool showSuccessMessage = true}) async {
    print('LogoutHelper: Starting logout process');

    try {
      // Lakukan proses logout tetapi dengan timeout untuk menghindari proses yang terlalu lama
      print('LogoutHelper: Calling authProvider.logout()');
      await authProvider.logout().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('LogoutHelper: Logout timeout, forcing state reset');
          // Reset state secara manual jika timeout
          authProvider.forceResetState();
          return;
        },
      );
      print('LogoutHelper: Logout API call completed');
    } catch (e) {
      print('LogoutHelper: Error during logout: $e');
      // Reset state walaupun ada error
      authProvider.forceResetState();
    } finally {
      // Selalu navigasi ke login screen terlepas dari hasil logout
      if (context.mounted) {
        print('LogoutHelper: Force navigating to login screen');

        // PENTING: Gunakan metode yang paling langsung untuk berpindah ke login screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Tutup semua dialog yang mungkin masih terbuka
          while (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          // Navigasi langsung ke login page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  LoginScreen(showLogoutMessage: showSuccessMessage),
            ),
          );

          print('LogoutHelper: Navigation command issued');
        });
      }
    }
  }
}
