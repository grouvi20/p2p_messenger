import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:p2p_messenger/models/message.dart';
import 'package:p2p_messenger/models/user.dart';

class StorageService {
  late SharedPreferences _prefs;
  final Map<String, Completer<void>?> _writeLocks = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User
  Future<void> saveCurrentUser(User user) async {
    await _prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  User? getCurrentUser() {
    final data = _prefs.getString('current_user');
    if (data == null) return null;
    return User.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> clearCurrentUser() async {
    await _prefs.remove('current_user');
  }

  // Server URL
  Future<void> saveServerUrl(String url) async {
    await _prefs.setString('server_url', url);
  }

  String? getServerUrl() => _prefs.getString('server_url');

  // Serialize writes per chatId to prevent race conditions
  Future<void> _serializedWrite(String chatId, Future<void> Function() op) async {
    while (_writeLocks[chatId] != null) {
      await _writeLocks[chatId]!.future;
    }
    final completer = Completer<void>();
    _writeLocks[chatId] = completer;
    try {
      await op();
    } finally {
      _writeLocks[chatId] = null;
      completer.complete();
    }
  }

  // Messages
  Future<void> saveMessage(Message message) async {
    await _serializedWrite(message.chatId, () async {
      final messages = getMessages(message.chatId);
      messages.add(message);
      await _prefs.setString(
        'messages_${message.chatId}',
        jsonEncode(messages.map((m) => m.toJson()).toList()),
      );
    });
  }

  Future<void> updateMessage(Message message) async {
    await _serializedWrite(message.chatId, () async {
      final messages = getMessages(message.chatId);
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index] = message;
        await _prefs.setString(
          'messages_${message.chatId}',
          jsonEncode(messages.map((m) => m.toJson()).toList()),
        );
      }
    });
  }

  List<Message> getMessages(String chatId) {
    final data = _prefs.getString('messages_$chatId');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Contacts
  Future<void> saveContacts(List<User> contacts) async {
    await _prefs.setString(
      'contacts',
      jsonEncode(contacts.map((c) => c.toJson()).toList()),
    );
  }

  List<User> getContacts() {
    final data = _prefs.getString('contacts');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Theme
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString('theme_mode', mode);
  }

  String getThemeMode() => _prefs.getString('theme_mode') ?? 'system';
}
