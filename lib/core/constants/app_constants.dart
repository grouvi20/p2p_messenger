import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'P2P Messenger';
  static const String _localServer = 'ws://localhost:8080/ws';
  static const String _deployedServer =
      'wss://p2p-signaling-server-ztvhsuhk.fly.dev/ws';

  static String get defaultSignalingServer {
    if (kIsWeb) {
      return _deployedServer;
    }
    return _localServer;
  }

  static const int reconnectDelaySeconds = 3;
  static const int maxReconnectAttempts = 10;
  static const int messagePageSize = 50;
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
}
