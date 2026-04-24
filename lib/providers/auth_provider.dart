import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:p2p_messenger/models/user.dart';
import 'package:p2p_messenger/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  User? _currentUser;

  AuthProvider(this._storage) {
    _currentUser = _storage.getCurrentUser();
  }

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> login(String name, String displayName) async {
    // Reuse existing user if available (preserves ID across logout/login)
    final existing = _storage.getCurrentUser();
    if (existing != null) {
      _currentUser = existing.copyWith(
        displayName: displayName,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
    } else {
      final id = const Uuid().v4();
      _currentUser = User(
        id: id,
        username: id.substring(0, 8),
        displayName: displayName,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
    }
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    // Only clear the in-memory user; keep stored user data for re-login
    notifyListeners();
  }
}
