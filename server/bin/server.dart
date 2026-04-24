import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SignalingServer {
  final Map<String, WebSocketChannel> _clients = {};
  final Map<String, List<Map<String, dynamic>>> _messageQueues = {};
  final Map<String, Map<String, dynamic>> _userProfiles = {};

  shelf.Handler get handler {
    return webSocketHandler((WebSocketChannel socket, String? protocol) {
      String? userId;

      socket.stream.listen(
        (data) {
          try {
            final message =
                jsonDecode(data as String) as Map<String, dynamic>;
            final event = message['event'] as String?;
            final payload =
                message['data'] as Map<String, dynamic>? ?? {};

            switch (event) {
              case 'register':
                userId = payload['userId'] as String?;
                if (userId != null) {
                  _clients[userId!] = socket;
                  _userProfiles[userId!] = {
                    'userId': userId,
                    'username': payload['username'] ?? userId,
                    'displayName': payload['displayName'] ?? userId,
                    'isOnline': true,
                    'lastSeen': DateTime.now().toIso8601String(),
                  };

                  // Notify others
                  _broadcast('user_online', {'userId': userId}, exclude: userId);

                  // Deliver queued messages
                  _deliverQueuedMessages(userId!);

                  print('User registered: $userId');
                }
              case 'message':
                _handleMessage(payload);
              case 'message_delivered':
                _relay(payload['senderId'] as String?, event!, payload);
              case 'message_read':
                _relay(payload['senderId'] as String?, event!, payload);
              case 'typing':
                _relay(payload['receiverId'] as String?, event!, payload);
              case 'search_users':
                _handleSearchUsers(userId, payload);
            }
          } catch (e) {
            print('Error processing message: $e');
          }
        },
        onDone: () {
          if (userId != null) {
            _clients.remove(userId);
            if (_userProfiles.containsKey(userId)) {
              _userProfiles[userId!]?['isOnline'] = false;
              _userProfiles[userId!]?['lastSeen'] =
                  DateTime.now().toIso8601String();
            }
            _broadcast('user_offline', {'userId': userId}, exclude: userId);
            print('User disconnected: $userId');
          }
        },
        onError: (error) {
          print('WebSocket error for $userId: $error');
        },
      );
    });
  }

  void _handleMessage(Map<String, dynamic> payload) {
    final receiverId = payload['receiverId'] as String?;
    if (receiverId == null) return;

    if (_clients.containsKey(receiverId)) {
      _send(receiverId, 'message', payload);
    } else {
      // Queue for offline delivery
      _messageQueues.putIfAbsent(receiverId, () => []).add(payload);
      print('Message queued for offline user: $receiverId');
    }
  }

  void _deliverQueuedMessages(String userId) {
    final queue = _messageQueues.remove(userId);
    if (queue != null && queue.isNotEmpty) {
      _send(userId, 'queued_messages', {'messages': queue});
      print('Delivered ${queue.length} queued messages to $userId');
    }
  }

  void _relay(String? targetId, String event, Map<String, dynamic> data) {
    if (targetId != null && _clients.containsKey(targetId)) {
      _send(targetId, event, data);
    }
  }

  void _handleSearchUsers(String? requesterId, Map<String, dynamic> payload) {
    if (requesterId == null) return;
    final query = (payload['query'] as String?)?.toLowerCase() ?? '';

    final results = _userProfiles.values
        .where((p) {
          if (p['userId'] == requesterId) return false;
          final username = (p['username'] as String?)?.toLowerCase() ?? '';
          final displayName = (p['displayName'] as String?)?.toLowerCase() ?? '';
          return username.contains(query) || displayName.contains(query);
        })
        .toList();

    _send(requesterId, 'search_results', {'users': results});
  }

  void _send(
      String userId, String event, Map<String, dynamic> data) {
    final client = _clients[userId];
    if (client != null) {
      try {
        client.sink.add(jsonEncode({'event': event, 'data': data}));
      } catch (e) {
        print('Error sending to $userId: $e');
        _clients.remove(userId);
      }
    }
  }

  void _broadcast(String event, Map<String, dynamic> data,
      {String? exclude}) {
    for (final entry in _clients.entries) {
      if (entry.key != exclude) {
        _send(entry.key, event, data);
      }
    }
  }
}

Future<void> main(List<String> args) async {
  final port = int.tryParse(
          args.isNotEmpty ? args[0] : Platform.environment['PORT'] ?? '8080') ??
      8080;

  final server = SignalingServer();

  final cascade = shelf.Cascade()
      .add(server.handler)
      .add((shelf.Request request) {
    if (request.url.path == '' || request.url.path == '/') {
      return shelf.Response.ok(
        jsonEncode({
          'name': 'P2P Messenger Signaling Server',
          'version': '1.0.0',
          'status': 'running',
          'websocket': 'ws://localhost:$port',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return shelf.Response.notFound('Not found');
  });

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(cascade.handler);

  final httpServer = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Signaling server running on http://${httpServer.address.host}:${httpServer.port}');
  print('WebSocket endpoint: ws://localhost:$port');
}
