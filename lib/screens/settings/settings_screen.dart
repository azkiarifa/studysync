import 'package:flutter/material.dart';
import '../../services/sharedpref_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import '../../widgets/custom_button.dart';
import '../../main.dart'; // Import to reference themeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = true;
  bool _focusModeEnabled = false;
  String _selectedLanguage = 'id';
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _notificationEnabled = SharedPrefService.notification;
      _focusModeEnabled = SharedPrefService.focusMode;
      _selectedLanguage = SharedPrefService.language;
      _isDarkMode = SharedPrefService.themeMode == 'dark';
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    final modeString = isDark ? 'dark' : 'light';
    await SharedPrefService.setThemeMode(modeString);
    setState(() {
      _isDarkMode = isDark;
    });
    // Trigger global theme update
    StudySyncApp.themeNotifier.value = isDark
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> _toggleNotification(bool enabled) async {
    await SharedPrefService.setNotification(enabled);
    setState(() {
      _notificationEnabled = enabled;
    });
  }

  Future<void> _toggleFocusMode(bool enabled) async {
    await SharedPrefService.setFocusMode(enabled);
    setState(() {
      _focusModeEnabled = enabled;
    });
  }

  Future<void> _changeLanguage(String? lang) async {
    if (lang != null) {
      await SharedPrefService.setLanguage(lang);
      setState(() {
        _selectedLanguage = lang;
      });
      StudySyncApp.languageNotifier.value++;
    }
  }

  Future<void> _resetPreferences() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Pengaturan'),
        content: const Text(
          'Apakah Anda yakin ingin mengembalikan semua pengaturan ke default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await SharedPrefService.clearAll();
              await SharedPrefService.setFirstLaunch(false); // keep false
              _loadSettings();
              // Reset theme notifier
              StudySyncApp.themeNotifier.value = ThemeMode.dark;
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pengaturan berhasil direset')),
                );
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(AppText.get('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Section Tampilan
          Text(
            AppText.get('display'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: Text(AppText.get('darkMode')),
              trailing: Switch(
                value: _isDarkMode,
                activeColor: AppColors.primary,
                onChanged: _toggleTheme,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section Notifikasi & Fokus
          Text(
            AppText.get('focusSecurity'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_rounded),
                  title: Text(AppText.get('notifications')),
                  trailing: Switch(
                    value: _notificationEnabled,
                    activeColor: AppColors.primary,
                    onChanged: _toggleNotification,
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                ListTile(
                  leading: const Icon(Icons.do_not_disturb_on_rounded),
                  title: Text(AppText.get('focusMode')),
                  subtitle: Text(AppText.get('focusModeDesc')),
                  trailing: Switch(
                    value: _focusModeEnabled,
                    activeColor: AppColors.primary,
                    onChanged: _toggleFocusMode,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Bahasa
          Text(
            AppText.get('language'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(AppText.get('chooseLanguage')),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'id',
                    child: Text('Bahasa Indonesia'),
                  ),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: _changeLanguage,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Reset Button
          CustomButton(
            text: AppText.get('resetDefault'),
            onTap: _resetPreferences,
            gradient: const LinearGradient(
              colors: [AppColors.danger, Colors.orange],
            ),
            icon: Icons.restore_rounded,
          ),
        ],
      ),
    );
  }
}
