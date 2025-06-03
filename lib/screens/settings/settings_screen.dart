import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    // Jika settings belum dimuat, muat terlebih dahulu
    if (settingsProvider.settings == null && userId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settingsProvider.loadSettings(userId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: true,
      ),
      body: settingsProvider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : settingsProvider.error != null
          ? _buildErrorView(context, settingsProvider, userId)
          : settingsProvider.settings == null
            ? const Center(
                child: Text('Pengaturan belum tersedia. Harap tunggu sebentar...'),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tampilan
                  _buildSectionHeader(context, 'Tampilan'),
                  SwitchListTile(
                    title: const Text('Mode Gelap'),
                    subtitle: const Text('Menggunakan tema gelap untuk aplikasi'),
                    value: settingsProvider.isDarkMode,
                    onChanged: (value) {
                      if (userId.isNotEmpty) {
                        try {
                          settingsProvider.updateTheme(userId, value);
                        } catch (e) {
                          _showErrorSnackbar(context, 'Gagal mengubah tema: $e');
                        }
                      } else {
                        _showErrorSnackbar(context, 'Anda harus login terlebih dahulu');
                      }
                    },
                  ),
                  const Divider(),

                  // Suara
                  _buildSectionHeader(context, 'Suara dan Notifikasi'),
                  SwitchListTile(
                    title: const Text('Text-to-Speech'),
                    subtitle: const Text('Ucapkan frasa saat latihan'),
                    value: settingsProvider.enableTTS,
                    onChanged: (value) {
                      if (userId.isNotEmpty) {
                        try {
                          settingsProvider.updateNotificationSettings(
                            userId,
                            enableNotifications: settingsProvider.enableNotifications,
                            notificationTime: settingsProvider.notificationTime,
                          );
                        } catch (e) {
                          _showErrorSnackbar(context, 'Gagal mengubah pengaturan TTS: $e');
                        }
                      } else {
                        _showErrorSnackbar(context, 'Anda harus login terlebih dahulu');
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Notifikasi'),
                    subtitle: const Text('Aktifkan pengingat latihan harian'),
                    value: settingsProvider.enableNotifications,
                    onChanged: (value) {
                      if (userId.isNotEmpty) {
                        try {
                          settingsProvider.updateNotificationSettings(
                            userId,
                            enableNotifications: value,
                            notificationTime: settingsProvider.notificationTime,
                          );
                        } catch (e) {
                          _showErrorSnackbar(context, 'Gagal mengubah pengaturan notifikasi: $e');
                        }
                      } else {
                        _showErrorSnackbar(context, 'Anda harus login terlebih dahulu');
                      }
                    },
                  ),
                  if (settingsProvider.enableNotifications)
                    ListTile(
                      title: const Text('Waktu Notifikasi'),
                      subtitle: Text(settingsProvider.notificationTime),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () =>
                          _selectNotificationTime(context, settingsProvider, userId),
                    ),
                  const Divider(),

                  // Target harian
                  _buildSectionHeader(context, 'Target Harian'),
                  ListTile(
                    title: const Text('Target Latihan Harian'),
                    subtitle: Text('${settingsProvider.dailyGoal} frasa per hari'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectDailyGoal(context, settingsProvider, userId),
                  ),
                  const Divider(),

                  // Tentang aplikasi
                  _buildSectionHeader(context, 'Tentang Aplikasi'),
                  ListTile(
                    title: const Text('Versi Aplikasi'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    title: const Text('Kebijakan Privasi'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Implementasi navigasi ke kebijakan privasi
                    },
                  ),
                  ListTile(
                    title: const Text('Syarat dan Ketentuan'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Implementasi navigasi ke syarat dan ketentuan
                    },
                  ),
                ],
              ),
    );
  }

  Widget _buildErrorView(BuildContext context, SettingsProvider provider, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Gagal memuat pengaturan', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (userId.isNotEmpty) {
                provider.resetError();
                provider.loadSettings(userId);
              }
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _selectNotificationTime(
      BuildContext context, SettingsProvider provider, String userId) async {
    if (userId.isEmpty) {
      _showErrorSnackbar(context, 'Anda harus login terlebih dahulu');
      return;
    }

    final currentTime = provider.notificationTime.split(':');
    final TimeOfDay initialTime = TimeOfDay(
      hour: int.parse(currentTime[0]),
      minute: int.parse(currentTime[1]),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      final newTime =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      try {
        provider.updateNotificationSettings(
          userId,
          enableNotifications: provider.enableNotifications,
          notificationTime: newTime,
        );
      } catch (e) {
        _showErrorSnackbar(context, 'Gagal mengubah waktu notifikasi: $e');
      }
    }
  }

  Future<void> _selectDailyGoal(
      BuildContext context, SettingsProvider provider, String userId) async {
    if (userId.isEmpty) {
      _showErrorSnackbar(context, 'Anda harus login terlebih dahulu');
      return;
    }

    final goalOptions = [5, 10, 15, 20, 25, 30, 50];
    final int? selectedGoal = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Target Harian'),
        children: goalOptions.map((goal) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, goal);
            },
            child: Text('$goal frasa per hari'),
          );
        }).toList(),
      ),
    );

    if (selectedGoal != null) {
      try {
        provider.updateDailyGoal(userId, selectedGoal);
      } catch (e) {
        _showErrorSnackbar(context, 'Gagal mengubah target harian: $e');
      }
    }
  }
}
