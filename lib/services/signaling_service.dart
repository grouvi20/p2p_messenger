import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:p2p_messenger/core/constants/app_constants.dart';

typedef SignalCallback = void Function(Map<String, dynamic> data);

class SignalingService {
  WebSocketChannel? _channel;
  final Map<String, List<SignalCallback>> _handlers = {};
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _serverUrl;
  String? _userId;
  bool _isConnected = false;
  bool _intentionalDisconnect = false;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  void on(String event, SignalCallback callback) {
    _handlers.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, [SignalCallback? callback]) {
    if (callback != null) {
      _handlers[event]?.remove(callback);
    } else {
      _handlers.remove(event);
    }
  }

  Future<void> connect(String serverUrl, String userId) async {
    _serverUrl = serverUrl;
    _userId = userId;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_serverUrl == null || _userId == null) return;
    _intentionalDisconnect = false;

    try {
      final uri = Uri.parse('$_serverUrl?userId=$_userId');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      send('register', {'userId': _userId});
    } catch (e) {
      debugPrint('Signaling connect error: $e');
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> message =
          jsonDecode(data as String) as Map<String, dynamic>;
      final event = message['event'] as String?;
      final payload = message['data'] as Map<String, dynamic>? ?? {};

      if (event != null && _handlers.containsKey(event)) {
        for (final handler in _handlers[event]!) {
          handler(payload);
        }
      }
    } catch (e) {
      debugPrint('Signaling message parse error: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void _onDone() {
    _isConnected = false;
    _connectionController.add(false);
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= AppConstants.maxReconnectAttempts) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: AppConstants.reconnectDelaySeconds),
      () {
        _reconnectAttempts++;
        _doConnect();
      },
    );
  }

  bool send(String event, Map<String, dynamic> data) {
    if (_channel == null) return false;
    final message = jsonEncode({'event': event, 'data': data});
    try {
      _channel!.sink.add(message);
      return true;
    } catch (e) {
      debugPrint('Send error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _isConnected = false;
    _connectionController.add(false);
    await _channel?.sink.close();
    _channel = null;
    _serverUrl = null;
    _userId = null;
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _connectionController.close();
    _channel?.sink.close();
  }
}
