import 'package:shared_preferences/shared_preferences.dart';

class ReaderThemeService {
  static const String defaultThemeId = 'black';

  static const String bodyBackgroundWhite = 'white';
  static const String bodyBackgroundTinted = 'tinted';
  static const String defaultBodyBackgroundMode = bodyBackgroundWhite;

  static const String _themeIdKey = 'reader_theme_id';
  static const String _bodyBackgroundModeKey = 'reader_body_background_mode';

  Future<String> getThemeId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_themeIdKey) ?? defaultThemeId;
  }

  Future<void> saveThemeId(String themeId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_themeIdKey, themeId);
  }

  Future<String> getBodyBackgroundMode() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_bodyBackgroundModeKey) ?? defaultBodyBackgroundMode;
  }

  Future<void> saveBodyBackgroundMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_bodyBackgroundModeKey, mode);
  }
}
