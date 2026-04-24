import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MediaService {
  String _serverUrl;

  MediaService(this._serverUrl);

  void updateServerUrl(String url) {
    // Convert ws:// to http://
    _serverUrl = url
        .replaceFirst('wss://', 'https://')
        .replaceFirst('ws://', 'http://')
        .replaceFirst('/ws', '');
  }

  String get _httpBase => _serverUrl
      .replaceFirst('wss://', 'https://')
      .replaceFirst('ws://', 'http://')
      .replaceFirst('/ws', '');

  /// Upload a file and return the server URL path
  Future<Map<String, dynamic>> uploadFile(
      Uint8List bytes, String fileName) async {
    final uri = Uri.parse('$_httpBase/upload');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'url': '$_httpBase${data['url']}',
      'fileName': data['originalName'] as String,
      'fileSize': data['size'] as int,
    };
  }

  /// Upload a file from path
  Future<Map<String, dynamic>> uploadFilePath(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final fileName = p.basename(filePath);
    return uploadFile(bytes, fileName);
  }

  /// Get full URL for a file path
  String getFileUrl(String urlOrPath) {
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return urlOrPath;
    }
    return '$_httpBase$urlOrPath';
  }

  /// Download file to local cache and return local path
  Future<String> downloadToCache(String url, String fileName) async {
    if (kIsWeb) return url;

    final dir = await getTemporaryDirectory();
    final localPath = '${dir.path}/p2p_media/$fileName';
    final localFile = File(localPath);

    if (localFile.existsSync()) return localPath;

    await Directory('${dir.path}/p2p_media').create(recursive: true);
    final response = await http.get(Uri.parse(url));
    await localFile.writeAsBytes(response.bodyBytes);
    return localPath;
  }
}
