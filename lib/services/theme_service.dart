import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorTheme { purple, blue, green, orange, pink, teal, indigo, red }

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorThemeKey = 'color_theme';

  ThemeMode _themeMode = ThemeMode.system;
  ColorTheme _colorTheme = ColorTheme.purple;

  ThemeMode get themeMode => _themeMode;
  ColorTheme get colorTheme => _colorTheme;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeModeIndex = prefs.getInt(_themeKey) ?? 0;
    switch (themeModeIndex) {
      case 0:
        _themeMode = ThemeMode.system;
        break;
      case 1:
        _themeMode = ThemeMode.light;
        break;
      case 2:
        _themeMode = ThemeMode.dark;
        break;
    }

    // Load color theme
    final colorThemeIndex = prefs.getInt(_colorThemeKey) ?? 0;
    _colorTheme = ColorTheme.values[colorThemeIndex];

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;

    final prefs = await SharedPreferences.getInstance();
    int themeModeIndex;

    switch (themeMode) {
      case ThemeMode.system:
        themeModeIndex = 0;
        break;
      case ThemeMode.light:
        themeModeIndex = 1;
        break;
      case ThemeMode.dark:
        themeModeIndex = 2;
        break;
    }

    await prefs.setInt(_themeKey, themeModeIndex);
    notifyListeners();
  }

  Future<void> setColorTheme(ColorTheme colorTheme) async {
    _colorTheme = colorTheme;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorThemeKey, colorTheme.index);

    notifyListeners();
  }

  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Color get seedColor {
    switch (_colorTheme) {
      case ColorTheme.purple:
        return const Color(0xFF6750A4);
      case ColorTheme.blue:
        return const Color(0xFF1976D2);
      case ColorTheme.green:
        return const Color(0xFF388E3C);
      case ColorTheme.orange:
        return const Color(0xFFFF9800);
      case ColorTheme.pink:
        return const Color(0xFFE91E63);
      case ColorTheme.teal:
        return const Color(0xFF00695C);
      case ColorTheme.indigo:
        return const Color(0xFF303F9F);
      case ColorTheme.red:
        return const Color(0xFFD32F2F);
    }
  }

  String get colorThemeName {
    switch (_colorTheme) {
      case ColorTheme.purple:
        return 'Purple';
      case ColorTheme.blue:
        return 'Blue';
      case ColorTheme.green:
        return 'Green';
      case ColorTheme.orange:
        return 'Orange';
      case ColorTheme.pink:
        return 'Pink';
      case ColorTheme.teal:
        return 'Teal';
      case ColorTheme.indigo:
        return 'Indigo';
      case ColorTheme.red:
        return 'Red';
    }
  }

  static List<Map<String, dynamic>> get availableColorThemes {
    return [
      {
        'theme': ColorTheme.purple,
        'name': 'Purple',
        'color': const Color(0xFF6750A4),
        'icon': Icons.palette,
      },
      {
        'theme': ColorTheme.blue,
        'name': 'Blue',
        'color': const Color(0xFF1976D2),
        'icon': Icons.water_drop,
      },
      {
        'theme': ColorTheme.green,
        'name': 'Green',
        'color': const Color(0xFF388E3C),
        'icon': Icons.eco,
      },
      {
        'theme': ColorTheme.orange,
        'name': 'Orange',
        'color': const Color(0xFFFF9800),
        'icon': Icons.wb_sunny,
      },
      {
        'theme': ColorTheme.pink,
        'name': 'Pink',
        'color': const Color(0xFFE91E63),
        'icon': Icons.favorite,
      },
      {
        'theme': ColorTheme.teal,
        'name': 'Teal',
        'color': const Color(0xFF00695C),
        'icon': Icons.waves,
      },
      {
        'theme': ColorTheme.indigo,
        'name': 'Indigo',
        'color': const Color(0xFF303F9F),
        'icon': Icons.nights_stay,
      },
      {
        'theme': ColorTheme.red,
        'name': 'Red',
        'color': const Color(0xFFD32F2F),
        'icon': Icons.local_fire_department,
      },
    ];
  }
}
