import 'dart:async';
import 'package:p2p_messenger/models/message.dart';
import 'package:p2p_messenger/services/signaling_service.dart';

/// P2P messaging service using WebSocket signaling for message relay.
/// Messages are routed through the signaling server which forwards them
/// to the target peer. When both peers are online, delivery is near-instant.
/// When a peer is offline, the server queues messages for later delivery.
class P2PService {
  final SignalingService _signaling;
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  final Map<String, bool> _peerOnlineStatus = {};

  P2PService(this._signaling);

  void init(String userId) {
    _signaling.on('message', _onMessageReceived);
    _signaling.on('message_delivered', _onMessageDelivered);
    _signaling.on('message_read', _onMessageRead);
    _signaling.on('typing', _onTyping);
    _signaling.on('user_online', _onUserOnline);
    _signaling.on('user_offline', _onUserOffline);
    _signaling.on('queued_messages', _onQueuedMessages);
  }

  void _onMessageReceived(Map<String, dynamic> data) {
    final message = Message.fromJson(data);
    _messageController.add(message);

    // Send delivery receipt
    _signaling.send('message_delivered', {
      'messageId': message.id,
      'senderId': message.senderId,
      'receiverId': message.receiverId,
    });
  }

  void _onMessageDelivered(Map<String, dynamic> data) {
    _eventController.add({'type': 'delivered', ...data});
  }

  void _onMessageRead(Map<String, dynamic> data) {
    _eventController.add({'type': 'read', ...data});
  }

  void _onTyping(Map<String, dynamic> data) {
    _eventController.add({'type': 'typing', ...data});
  }

  void _onUserOnline(Map<String, dynamic> data) {
    final peerId = data['userId'] as String;
    _peerOnlineStatus[peerId] = true;
    _eventController.add({'type': 'user_online', 'userId': peerId});
  }

  void _onUserOffline(Map<String, dynamic> data) {
    final peerId = data['userId'] as String;
    _peerOnlineStatus[peerId] = false;
    _eventController.add({'type': 'user_offline', 'userId': peerId});
  }

  void _onQueuedMessages(Map<String, dynamic> data) {
    final messages = data['messages'] as List?;
    if (messages != null) {
      for (final msgData in messages) {
        final message = Message.fromJson(msgData as Map<String, dynamic>);
        _messageController.add(message);
      }
    }
  }

  void sendMessage(Message message) {
    _signaling.send('message', message.toJson());
  }

  void sendTypingIndicator(String peerId, String senderId) {
    _signaling.send('typing', {
      'senderId': senderId,
      'receiverId': peerId,
    });
  }

  void markAsRead(String messageId, String senderId, String receiverId) {
    _signaling.send('message_read', {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  bool isPeerOnline(String peerId) => _peerOnlineStatus[peerId] ?? false;

  void searchUsers(String query) {
    _signaling.send('search_users', {'query': query});
  }

  void dispose() {
    _signaling.off('message');
    _signaling.off('message_delivered');
    _signaling.off('message_read');
    _signaling.off('typing');
    _signaling.off('user_online');
    _signaling.off('user_offline');
    _signaling.off('queued_messages');
    _messageController.close();
    _eventController.close();
  }
}
