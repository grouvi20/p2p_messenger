import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p2p_messenger/core/constants/app_constants.dart';
import 'package:p2p_messenger/services/media_service.dart';
import 'package:p2p_messenger/services/p2p_service.dart';
import 'package:p2p_messenger/services/signaling_service.dart';
import 'package:p2p_messenger/services/storage_service.dart';

enum ConnectionState { disconnected, connecting, connected }

class ConnectionProvider extends ChangeNotifier {
  final SignalingService _signaling;
  final P2PService _p2p;
  final StorageService _storage;
  final MediaService _media;
  ConnectionState _state = ConnectionState.disconnected;
  StreamSubscription<bool>? _connectionSubscription;
  String _serverUrl = AppConstants.defaultSignalingServer;

  ConnectionProvider(this._signaling, this._p2p, this._storage, this._media) {
    final savedUrl = _storage.getServerUrl();
    if (savedUrl != null) {
      _serverUrl = savedUrl;
      _media.updateServerUrl(savedUrl);
    }
  }

  ConnectionState get state => _state;
  String get serverUrl => _serverUrl;
  bool get isConnected => _state == ConnectionState.connected;

  Future<void> connect(String userId) async {
    if (_state == ConnectionState.connecting || _state == ConnectionState.connected) return;
    _state = ConnectionState.connecting;
    notifyListeners();

    _connectionSubscription?.cancel();
    _connectionSubscription = _signaling.connectionStream.listen((connected) {
      _state =
          connected ? ConnectionState.connected : ConnectionState.disconnected;
      notifyListeners();
    });

    await _signaling.connect(_serverUrl, userId);
    _p2p.init(userId);
  }

  Future<void> updateServerUrl(String url) async {
    _serverUrl = url;
    await _storage.saveServerUrl(url);
    _media.updateServerUrl(url);
    notifyListeners();
  }

  Future<void> disconnect() async {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _signaling.disconnect();
    _state = ConnectionState.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
