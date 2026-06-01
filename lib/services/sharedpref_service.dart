import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SharedPrefService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Getters
  static String get username => _prefs?.getString(AppConstants.keyUsername) ?? AppConstants.defaultUsername;
  static String get semester => _prefs?.getString(AppConstants.keySemester) ?? AppConstants.defaultSemester;
  static String get themeMode => _prefs?.getString(AppConstants.keyThemeMode) ?? AppConstants.defaultThemeMode;
  static bool get notification => _prefs?.getBool(AppConstants.keyNotification) ?? true;
  static bool get focusMode => _prefs?.getBool(AppConstants.keyFocusMode) ?? false;
  static String get profileImage => _prefs?.getString(AppConstants.keyProfileImage) ?? '';
  static String get language => _prefs?.getString(AppConstants.keyLanguage) ?? AppConstants.defaultLanguage;
  static bool get isFirstLaunch => _prefs?.getBool(AppConstants.keyFirstLaunch) ?? true;

  // Setters
  static Future<bool> setUsername(String value) async {
    return await _prefs?.setString(AppConstants.keyUsername, value) ?? false;
  }

  static Future<bool> setSemester(String value) async {
    return await _prefs?.setString(AppConstants.keySemester, value) ?? false;
  }

  static Future<bool> setThemeMode(String value) async {
    return await _prefs?.setString(AppConstants.keyThemeMode, value) ?? false;
  }

  static Future<bool> setNotification(bool value) async {
    return await _prefs?.setBool(AppConstants.keyNotification, value) ?? false;
  }

  static Future<bool> setFocusMode(bool value) async {
    return await _prefs?.setBool(AppConstants.keyFocusMode, value) ?? false;
  }

  static Future<bool> setProfileImage(String value) async {
    return await _prefs?.setString(AppConstants.keyProfileImage, value) ?? false;
  }

  static Future<bool> setLanguage(String value) async {
    return await _prefs?.setString(AppConstants.keyLanguage, value) ?? false;
  }

  static Future<bool> setFirstLaunch(bool value) async {
    return await _prefs?.setBool(AppConstants.keyFirstLaunch, value) ?? false;
  }

  // Clear / Reset
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
