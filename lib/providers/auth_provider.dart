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

  Future<void> login(String username, String displayName) async {
    _currentUser = User(
      id: const Uuid().v4(),
      username: username,
      displayName: displayName,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
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
    await _storage.clearCurrentUser();
    notifyListeners();
  }
}
