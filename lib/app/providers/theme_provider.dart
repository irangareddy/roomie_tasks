import 'package:flutter/material.dart';

import 'package:roomie_tasks/app/services/services.dart';

class ThemeProvider with ChangeNotifier {
  ThemeProvider(this._storageService) {
    _loadThemePreference();
  }
  final StorageService _storageService;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    _isDarkMode =
        await _storageService.get(StorageKey.isDarkMode) as bool? ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.set(StorageKey.isDarkMode, _isDarkMode);
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
