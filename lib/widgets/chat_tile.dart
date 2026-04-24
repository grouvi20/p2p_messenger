import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p2p_messenger/models/chat.dart';
import 'package:p2p_messenger/models/message.dart';
import 'package:p2p_messenger/widgets/avatar_widget.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatTile({
    super.key,
    required this.chat,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEE').format(time);
    }
    return DateFormat('dd.MM.yy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withAlpha(20)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              AvatarWidget(
                name: chat.peer.displayName,
                imageUrl: chat.peer.avatarUrl,
                size: 52,
                showOnline: true,
                isOnline: chat.peer.isOnline,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.peer.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.lastMessage != null)
                          Text(
                            _formatTime(chat.lastMessage!.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: chat.unreadCount > 0
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodySmall?.color,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: chat.isPeerTyping
                              ? Text(
                                  'typing...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(
                                  _lastMessagePreview(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        if (chat.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chat.unreadCount > 99
                                  ? '99+'
                                  : chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _lastMessagePreview() {
    final msg = chat.lastMessage;
    if (msg == null) return 'No messages yet';
    switch (msg.type) {
      case MessageType.image:
        return '\u{1F4F7} Photo';
      case MessageType.voice:
        return '\u{1F3A4} Voice message';
      case MessageType.video:
        return '\u{1F4F9} Video message';
      case MessageType.file:
        return '\u{1F4CE} ${msg.fileName ?? 'File'}';
      default:
        return msg.content;
    }
  }
}
