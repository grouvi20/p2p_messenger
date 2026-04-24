import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:p2p_messenger/models/user.dart';
import 'package:p2p_messenger/providers/chat_provider.dart';
import 'package:p2p_messenger/widgets/avatar_widget.dart';

class ContactsScreen extends StatefulWidget {
  final void Function(String chatId)? onChatStarted;

  const ContactsScreen({super.key, this.onChatStarted});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddContactDialog() {
    final usernameController = TextEditingController();
    final displayNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                hintText: 'User ID or Username',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(
                hintText: 'Display Name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final userId = usernameController.text.trim();
              final displayName = displayNameController.text.trim();
              if (userId.isEmpty || displayName.isEmpty) return;

              final peer = User(
                id: userId.length < 10 ? const Uuid().v4() : userId,
                username: userId,
                displayName: displayName,
                lastSeen: DateTime.now(),
              );

              final chat = context.read<ChatProvider>().startChat(peer);
              Navigator.pop(context);
              widget.onChatStarted?.call(chat.id);
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          final contacts = chatProvider.chats.map((c) => c.peer).toList();
          final query = _searchController.text.toLowerCase();
          final filtered = query.isEmpty
              ? contacts
              : contacts
                  .where((c) =>
                      c.displayName.toLowerCase().contains(query) ||
                      c.username.toLowerCase().contains(query))
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 80,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withAlpha(76),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No contacts yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _showAddContactDialog,
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('Add Contact'),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Padding(
                          padding: const EdgeInsets.only(left: 82),
                          child: Divider(
                            height: 1,
                            color: Theme.of(context).dividerTheme.color,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final contact = filtered[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: AvatarWidget(
                              name: contact.displayName,
                              imageUrl: contact.avatarUrl,
                              size: 48,
                              showOnline: true,
                              isOnline: contact.isOnline,
                            ),
                            title: Text(
                              contact.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '@${contact.username}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.chat_rounded),
                              onPressed: () {
                                final chat =
                                    context.read<ChatProvider>().startChat(contact);
                                widget.onChatStarted?.call(chat.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
