import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider with ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _keyTheme = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final savedThemeIndex = box.get(_keyTheme);
    if (savedThemeIndex != null) {
      _themeMode = ThemeMode.values[savedThemeIndex];
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_keyTheme, mode.index);
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
