import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'services/sharedpref_service.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences service
  await SharedPrefService.init();

  // Retrieve stored theme mode to initialize theme state
  final storedTheme = SharedPrefService.themeMode;
  ThemeMode initialThemeMode = ThemeMode.dark; // Default
  if (storedTheme == 'light') {
    initialThemeMode = ThemeMode.light;
  }

  StudySyncApp.themeNotifier.value = initialThemeMode;

  runApp(const StudySyncApp());
}

class StudySyncApp extends StatelessWidget {
  // Global theme switcher notifier
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.dark,
  );
  static final ValueNotifier<int> languageNotifier = ValueNotifier(0);

  const StudySyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return ValueListenableBuilder<int>(
          valueListenable: languageNotifier,
          builder: (_, __, ___) {
            return MaterialApp(
              title: 'StudySync',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
