import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p2p_messenger/models/chat.dart';
import 'package:p2p_messenger/providers/chat_provider.dart';
import 'package:p2p_messenger/widgets/chat_tile.dart';

class ChatListScreen extends StatelessWidget {
  final void Function(Chat chat)? onChatSelected;
  final String? selectedChatId;

  const ChatListScreen({
    super.key,
    this.onChatSelected,
    this.selectedChatId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final chats = chatProvider.chats;

        if (chats.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_rounded,
                    size: 64,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withAlpha(60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go to Contacts to start a conversation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, _) => Padding(
            padding: const EdgeInsets.only(left: 82),
            child: Divider(
              height: 1,
              color: Theme.of(context).dividerTheme.color,
            ),
          ),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ChatTile(
              chat: chat,
              isSelected: chat.id == selectedChatId,
              onTap: () => onChatSelected?.call(chat),
              onLongPress: () => _showChatOptions(context, chat),
            );
          },
        );
      },
    );
  }

  void _showChatOptions(BuildContext context, Chat chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(76),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete Chat'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().deleteChat(chat.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
