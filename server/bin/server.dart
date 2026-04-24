import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

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
    for (final entry in _clients.entries.toList()) {
      if (entry.key != exclude) {
        _send(entry.key, event, data);
      }
    }
  }
}

/// Simple file storage for media uploads
class FileStorage {
  final String _uploadDir;
  final _uuid = const Uuid();

  FileStorage(this._uploadDir) {
    Directory(_uploadDir).createSync(recursive: true);
  }

  Future<Map<String, String>> saveFile(
      Uint8List bytes, String originalName) async {
    final ext = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '';
    final fileId = _uuid.v4();
    final storedName = '$fileId$ext';
    final file = File('$_uploadDir/$storedName');
    await file.writeAsBytes(bytes);
    return {'fileId': fileId, 'storedName': storedName};
  }

  File? getFile(String storedName) {
    final file = File('$_uploadDir/$storedName');
    return file.existsSync() ? file : null;
  }
}

Future<void> main(List<String> args) async {
  final port = int.tryParse(
          args.isNotEmpty ? args[0] : Platform.environment['PORT'] ?? '8080') ??
      8080;

  final server = SignalingServer();
  final fileStorage = FileStorage('uploads');

  // CORS middleware for web
  shelf.Middleware corsMiddleware() {
    return (shelf.Handler handler) {
      return (shelf.Request request) async {
        if (request.method == 'OPTIONS') {
          return shelf.Response.ok('', headers: _corsHeaders);
        }
        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  // File upload handler (multipart)
  Future<shelf.Response> handleUpload(shelf.Request request) async {
    try {
      final contentType = request.headers['content-type'] ?? '';

      if (contentType.contains('multipart/form-data')) {
        final boundary = contentType.split('boundary=').last;
        final body = await request.read().toBytes();
        final parts = _parseMultipart(body, boundary);

        if (parts.isEmpty) {
          return shelf.Response(400,
              body: jsonEncode({'error': 'No file provided'}),
              headers: {'Content-Type': 'application/json', ..._corsHeaders});
        }

        final part = parts.first;
        final result =
            await fileStorage.saveFile(part['bytes'] as Uint8List, part['filename'] as String);

        return shelf.Response.ok(
          jsonEncode({
            'fileId': result['fileId'],
            'fileName': result['storedName'],
            'url': '/files/${result['storedName']}',
            'originalName': part['filename'],
            'size': (part['bytes'] as Uint8List).length,
          }),
          headers: {'Content-Type': 'application/json', ..._corsHeaders},
        );
      }

      // Raw binary upload with filename in header
      final fileName = request.headers['x-filename'] ?? 'file';
      final bytes = await request.read().toBytes();
      final result = await fileStorage.saveFile(Uint8List.fromList(bytes), fileName);

      return shelf.Response.ok(
        jsonEncode({
          'fileId': result['fileId'],
          'fileName': result['storedName'],
          'url': '/files/${result['storedName']}',
          'originalName': fileName,
          'size': bytes.length,
        }),
        headers: {'Content-Type': 'application/json', ..._corsHeaders},
      );
    } catch (e) {
      print('Upload error: $e');
      return shelf.Response.internalServerError(
          body: jsonEncode({'error': 'Upload failed: $e'}),
          headers: {'Content-Type': 'application/json', ..._corsHeaders});
    }
  }

  // File download handler
  shelf.Response handleDownload(shelf.Request request, String fileName) {
    final file = fileStorage.getFile(fileName);
    if (file == null) {
      return shelf.Response.notFound('File not found',
          headers: _corsHeaders);
    }

    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        : '';
    final mimeType = _getMimeType(ext);

    return shelf.Response.ok(
      file.openRead(),
      headers: {
        'Content-Type': mimeType,
        'Content-Length': file.lengthSync().toString(),
        'Cache-Control': 'public, max-age=86400',
        ..._corsHeaders,
      },
    );
  }

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addMiddleware(corsMiddleware())
      .addHandler((shelf.Request request) async {
    final path = request.url.path;

    // WebSocket upgrade
    if (request.headers['upgrade']?.toLowerCase() == 'websocket') {
      return server.handler(request);
    }

    // File upload
    if (path == 'upload' && request.method == 'POST') {
      return handleUpload(request);
    }

    // File download
    if (path.startsWith('files/')) {
      final fileName = path.substring(6);
      return handleDownload(request, fileName);
    }

    // Health check
    if (path == '' || path == '/') {
      return shelf.Response.ok(
        jsonEncode({
          'name': 'P2P Messenger Signaling Server',
          'version': '2.0.0',
          'status': 'running',
          'websocket': 'ws://localhost:$port',
          'upload': 'http://localhost:$port/upload',
          'files': 'http://localhost:$port/files/{fileName}',
        }),
        headers: {'Content-Type': 'application/json', ..._corsHeaders},
      );
    }

    return shelf.Response.notFound('Not found', headers: _corsHeaders);
  });

  final httpServer = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Signaling server running on http://${httpServer.address.host}:${httpServer.port}');
  print('WebSocket endpoint: ws://localhost:$port');
  print('File upload: http://localhost:$port/upload');
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Filename',
};

String _getMimeType(String ext) {
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
    case 'webm':
      return 'video/webm';
    case 'mp3':
      return 'audio/mpeg';
    case 'm4a':
      return 'audio/mp4';
    case 'ogg':
      return 'audio/ogg';
    case 'wav':
      return 'audio/wav';
    case 'aac':
      return 'audio/aac';
    case 'pdf':
      return 'application/pdf';
    default:
      return 'application/octet-stream';
  }
}

/// Parse simple multipart form data
List<Map<String, dynamic>> _parseMultipart(List<int> body, String boundary) {
  final parts = <Map<String, dynamic>>[];
  final bodyStr = utf8.decode(body, allowMalformed: true);

  final sections = bodyStr.split('--$boundary');

  for (final section in sections) {
    if (section.trim() == '--' || section.trim().isEmpty) continue;

    final headerEnd = section.indexOf('\r\n\r\n');
    if (headerEnd == -1) continue;

    final headers = section.substring(0, headerEnd);
    final filenameMatch = RegExp(r'filename="([^"]*)"').firstMatch(headers);
    if (filenameMatch == null) continue;

    final filename = filenameMatch.group(1) ?? 'file';
    // Get the byte offset for the content
    final headerByteLen = utf8.encode(section.substring(0, headerEnd + 4)).length;
    final sectionBytes = utf8.encode(section);
    final contentBytes = sectionBytes.sublist(headerByteLen);

    // Remove trailing \r\n
    final trimmed = contentBytes.length > 2 &&
            contentBytes[contentBytes.length - 2] == 13 &&
            contentBytes[contentBytes.length - 1] == 10
        ? contentBytes.sublist(0, contentBytes.length - 2)
        : contentBytes;

    parts.add({
      'filename': filename,
      'bytes': Uint8List.fromList(trimmed),
    });
  }

  return parts;
}

extension on Stream<List<int>> {
  Future<List<int>> toBytes() async {
    final builder = BytesBuilder();
    await forEach(builder.add);
    return builder.takeBytes();
  }
}
