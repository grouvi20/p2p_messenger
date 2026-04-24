import 'package:flutter/material.dart';
import 'package:p2p_messenger/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this._storage) {
    final saved = _storage.getThemeMode();
    switch (saved) {
      case 'light':
        _themeMode = ThemeMode.light;
      case 'dark':
        _themeMode = ThemeMode.dark;
      default:
        _themeMode = ThemeMode.system;
    }
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(mode.name);
    notifyListeners();
  }
}
