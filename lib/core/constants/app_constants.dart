class AppConstants {
  static const String appName = 'P2P Messenger';
  static const String defaultSignalingServer = 'ws://localhost:8080/ws';
  static const int reconnectDelaySeconds = 3;
  static const int maxReconnectAttempts = 10;
  static const int messagePageSize = 50;
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
}
