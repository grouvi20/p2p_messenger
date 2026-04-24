import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p2p_messenger/core/utils/responsive.dart';
import 'package:p2p_messenger/models/chat.dart';
import 'package:p2p_messenger/providers/chat_provider.dart';
import 'package:p2p_messenger/widgets/avatar_widget.dart';
import 'package:p2p_messenger/widgets/chat_input.dart';
import 'package:p2p_messenger/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setActiveChat(widget.chat.id);
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id) {
      context.read<ChatProvider>().setActiveChat(widget.chat.id);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  context.read<ChatProvider>().setActiveChat(null);
                  Navigator.pop(context);
                },
              ),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            AvatarWidget(
              name: widget.chat.peer.displayName,
              imageUrl: widget.chat.peer.avatarUrl,
              size: 36,
              showOnline: true,
              isOnline: widget.chat.peer.isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.peer.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, provider, _) {
                      final chat = provider.chats
                          .where((c) => c.id == widget.chat.id)
                          .firstOrNull;
                      if (chat?.isPeerTyping ?? false) {
                        return Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }
                      return Text(
                        widget.chat.peer.isOnline
                            ? 'online'
                            : 'last seen recently',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                final messages = provider.getMessages(widget.chat.id);

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 48,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withAlpha(76),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Messages are P2P encrypted',
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final prevMessage =
                        index > 0 ? messages[index - 1] : null;
                    final showTail = prevMessage == null ||
                        prevMessage.senderId != message.senderId;

                    return MessageBubble(
                      message: message,
                      isMine: message.senderId !=
                          widget.chat.peer.id,
                      showTail: showTail,
                    );
                  },
                );
              },
            ),
          ),
          ChatInput(
            onSend: (text) {
              context.read<ChatProvider>().sendMessage(
                    widget.chat.id,
                    widget.chat.peer.id,
                    text,
                  );
            },
            onTyping: () {
              context.read<ChatProvider>().sendTyping(widget.chat.peer.id);
            },
          ),
        ],
      ),
    );
  }
}
