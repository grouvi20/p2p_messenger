import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:p2p_messenger/models/chat.dart';
import 'package:p2p_messenger/models/message.dart';
import 'package:p2p_messenger/models/user.dart';
import 'package:p2p_messenger/services/media_service.dart';
import 'package:p2p_messenger/services/notification_service.dart';
import 'package:p2p_messenger/services/p2p_service.dart';
import 'package:p2p_messenger/services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final P2PService _p2p;
  final StorageService _storage;
  final MediaService _media;
  final String _currentUserId;

  final List<Chat> _chats = [];
  final Map<String, List<Message>> _messages = {};
  String? _activeChatId;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  final Map<String, Timer> _typingTimers = {};

  ChatProvider(this._p2p, this._storage, this._media, this._currentUserId) {
    _loadChats();
    _listenToMessages();
    _listenToEvents();
  }

  List<Chat> get chats => List.unmodifiable(_chats);
  String? get activeChatId => _activeChatId;

  List<Message> getMessages(String chatId) =>
      List.unmodifiable(_messages[chatId] ?? []);

  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
    if (chatId != null) {
      final idx = _chats.indexWhere((c) => c.id == chatId);
      if (idx != -1) {
        _chats[idx] = _chats[idx].copyWith(unreadCount: 0);
      }
    }
    notifyListeners();
  }

  void _loadChats() {
    final contacts = _storage.getContacts();
    for (final contact in contacts) {
      final chatId = _getChatId(contact.id);
      final messages = _storage.getMessages(chatId);
      _messages[chatId] = messages;
      _chats.add(Chat(
        id: chatId,
        peer: contact,
        lastMessage: messages.isNotEmpty ? messages.last : null,
      ));
    }
    _sortChats();
  }

  void _listenToMessages() {
    _messageSubscription = _p2p.messageStream.listen((message) {
      _handleIncomingMessage(message);
    });
  }

  void _listenToEvents() {
    _eventSubscription = _p2p.eventStream.listen((event) {
      final type = event['type'] as String;
      switch (type) {
        case 'delivered':
          _handleDelivered(event);
        case 'read':
          _handleRead(event);
        case 'typing':
          _handleTyping(event);
        case 'user_online':
          _handleOnlineStatus(event['userId'] as String, true);
        case 'user_offline':
          _handleOnlineStatus(event['userId'] as String, false);
      }
    });
  }

  void _handleIncomingMessage(Message message) {
    final chatId = message.chatId;

    _messages.putIfAbsent(chatId, () => []);
    _messages[chatId]!.add(message);
    _storage.saveMessage(message);

    final chatIdx = _chats.indexWhere((c) => c.id == chatId);
    if (chatIdx != -1) {
      final isActive = _activeChatId == chatId;
      _chats[chatIdx] = _chats[chatIdx].copyWith(
        lastMessage: message,
        unreadCount:
            isActive ? 0 : _chats[chatIdx].unreadCount + 1,
        isPeerTyping: false,
      );
    } else {
      final shortId = message.senderId.length > 8
          ? message.senderId.substring(0, 8)
          : message.senderId;
      final peer = User(
        id: message.senderId,
        username: shortId,
        displayName: shortId,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      _chats.add(Chat(
        id: chatId,
        peer: peer,
        lastMessage: message,
        unreadCount: _activeChatId == chatId ? 0 : 1,
      ));
      _storage.saveContacts(_chats.map((c) => c.peer).toList());
    }

    if (_activeChatId != chatId) {
      final chat = _chats.firstWhere((c) => c.id == chatId);
      String body;
      switch (message.type) {
        case MessageType.image:
          body = '📷 Photo';
        case MessageType.voice:
          body = '🎤 Voice message';
        case MessageType.video:
          body = '📹 Video message';
        case MessageType.file:
          body = '📎 ${message.fileName ?? 'File'}';
        default:
          body = message.content;
      }
      NotificationService().showMessageNotification(
        title: chat.peer.displayName,
        body: body,
        payload: chatId,
      );
    }

    _sortChats();
    notifyListeners();
  }

  void _handleDelivered(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String;
    for (final entry in _messages.entries) {
      final idx = entry.value.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        entry.value[idx] =
            entry.value[idx].copyWith(status: MessageStatus.delivered);
        _storage.updateMessage(entry.value[idx]);
        notifyListeners();
        break;
      }
    }
  }

  void _handleRead(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String;
    for (final entry in _messages.entries) {
      final idx = entry.value.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        entry.value[idx] =
            entry.value[idx].copyWith(status: MessageStatus.read);
        _storage.updateMessage(entry.value[idx]);
        notifyListeners();
        break;
      }
    }
  }

  void _handleTyping(Map<String, dynamic> data) {
    final senderId = data['senderId'] as String;
    final chatId = _getChatId(senderId);
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx != -1) {
      _chats[idx] = _chats[idx].copyWith(isPeerTyping: true);
      notifyListeners();

      _typingTimers[senderId]?.cancel();
      _typingTimers[senderId] = Timer(const Duration(seconds: 3), () {
        final i = _chats.indexWhere((c) => c.id == chatId);
        if (i != -1) {
          _chats[i] = _chats[i].copyWith(isPeerTyping: false);
          notifyListeners();
        }
      });
    }
  }

  void _handleOnlineStatus(String peerId, bool online) {
    final idx = _chats.indexWhere((c) => c.peer.id == peerId);
    if (idx != -1) {
      _chats[idx] = _chats[idx].copyWith(
        peer: _chats[idx].peer.copyWith(
          isOnline: online,
          lastSeen: online ? null : DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  void sendMessage(String chatId, String peerId, String content,
      {MessageType type = MessageType.text,
      String? fileName,
      int? fileSize,
      int? duration,
      String? mimeType}) {
    final message = Message(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: _currentUserId,
      receiverId: peerId,
      content: content,
      type: type,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      fileName: fileName,
      fileSize: fileSize,
      duration: duration,
      mimeType: mimeType,
    );

    _messages.putIfAbsent(chatId, () => []);
    _messages[chatId]!.add(message);
    _storage.saveMessage(message);

    final sent = _p2p.sendMessage(message);

    final idx = _messages[chatId]!.indexWhere((m) => m.id == message.id);
    if (idx != -1) {
      final newStatus = sent ? MessageStatus.sent : MessageStatus.sending;
      _messages[chatId]![idx] =
          _messages[chatId]![idx].copyWith(status: newStatus);
      _storage.updateMessage(_messages[chatId]![idx]);
    }

    final chatIdx = _chats.indexWhere((c) => c.id == chatId);
    if (chatIdx != -1 && idx != -1) {
      _chats[chatIdx] = _chats[chatIdx].copyWith(lastMessage: _messages[chatId]![idx]);
    }

    _sortChats();
    notifyListeners();
  }

  /// Upload file and send as media message
  Future<void> sendMediaMessage({
    required String chatId,
    required String peerId,
    required Uint8List bytes,
    required String fileName,
    required MessageType type,
    int? duration,
  }) async {
    try {
      final result = await _media.uploadFile(bytes, fileName);
      sendMessage(
        chatId,
        peerId,
        result['url'] as String,
        type: type,
        fileName: result['fileName'] as String,
        fileSize: result['fileSize'] as int,
        duration: duration,
      );
    } catch (e) {
      debugPrint('Failed to send media: $e');
    }
  }

  /// Upload file from path and send
  Future<void> sendFileMessage({
    required String chatId,
    required String peerId,
    required String filePath,
    required MessageType type,
    int? duration,
  }) async {
    try {
      final result = await _media.uploadFilePath(filePath);
      sendMessage(
        chatId,
        peerId,
        result['url'] as String,
        type: type,
        fileName: result['fileName'] as String,
        fileSize: result['fileSize'] as int,
        duration: duration,
      );
    } catch (e) {
      debugPrint('Failed to send file: $e');
    }
  }

  void sendTyping(String peerId) {
    _p2p.sendTypingIndicator(peerId, _currentUserId);
  }

  Chat startChat(User peer) {
    final chatId = _getChatId(peer.id);
    final existing = _chats.where((c) => c.id == chatId);
    if (existing.isNotEmpty) return existing.first;

    final chat = Chat(id: chatId, peer: peer);
    _chats.insert(0, chat);
    _storage.saveContacts(_chats.map((c) => c.peer).toList());
    notifyListeners();
    return chat;
  }

  String _getChatId(String peerId) {
    final ids = [_currentUserId, peerId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  void _sortChats() {
    _chats.sort((a, b) {
      final aTime = a.lastMessage?.timestamp ?? DateTime(1970);
      final bTime = b.lastMessage?.timestamp ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
  }

  void deleteChat(String chatId) {
    _chats.removeWhere((c) => c.id == chatId);
    _messages.remove(chatId);
    _storage.saveContacts(_chats.map((c) => c.peer).toList());
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _eventSubscription?.cancel();
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
