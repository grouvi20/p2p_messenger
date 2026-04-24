import 'package:p2p_messenger/models/message.dart';
import 'package:p2p_messenger/models/user.dart';

class Chat {
  final String id;
  final User peer;
  final Message? lastMessage;
  final int unreadCount;
  final bool isPeerTyping;

  const Chat({
    required this.id,
    required this.peer,
    this.lastMessage,
    this.unreadCount = 0,
    this.isPeerTyping = false,
  });

  Chat copyWith({
    String? id,
    User? peer,
    Message? lastMessage,
    int? unreadCount,
    bool? isPeerTyping,
  }) {
    return Chat(
      id: id ?? this.id,
      peer: peer ?? this.peer,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isPeerTyping: isPeerTyping ?? this.isPeerTyping,
    );
  }
}
