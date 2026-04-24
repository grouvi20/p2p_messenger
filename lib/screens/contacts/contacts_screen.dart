import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:p2p_messenger/models/user.dart';
import 'package:p2p_messenger/providers/auth_provider.dart';
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
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final chatProvider = context.read<ChatProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, size: 24),
            SizedBox(width: 10),
            Text('New Chat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter their User ID to start chatting',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                hintText: 'User ID (e.g. a1b2c3d4)',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Name (optional)',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
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
              final peerId = idController.text.trim();
              if (peerId.isEmpty) return;

              final peerName = nameController.text.trim();
              final peer = User(
                id: peerId,
                username: peerId.length > 8
                    ? peerId.substring(0, 8)
                    : peerId,
                displayName:
                    peerName.isEmpty ? 'User $peerId' : peerName,
                lastSeen: DateTime.now(),
              );

              final chat = chatProvider.startChat(peer);
              Navigator.pop(context);
              widget.onChatStarted?.call(chat.id);
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  void _copyMyId() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    Clipboard.setData(ClipboardData(text: user.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your ID copied!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            tooltip: 'New chat',
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
              // My ID card
              _buildMyIdCard(context),
              if (contacts.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                child: filtered.isEmpty && contacts.isEmpty
                    ? _buildEmptyState(context)
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No results',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
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
                                  contact.isOnline
                                      ? 'online'
                                      : 'last seen recently',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: contact.isOnline
                                        ? const Color(0xFF4CAF50)
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.chat_rounded),
                                  onPressed: () {
                                    final chat = context
                                        .read<ChatProvider>()
                                        .startChat(contact);
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

  Widget _buildMyIdCard(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF353750)
            : Theme.of(context).colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.badge_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your ID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  user.id.substring(0, 8),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _copyMyId,
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color:
                  Theme.of(context).textTheme.bodySmall?.color?.withAlpha(76),
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your ID with friends, or enter\ntheir ID to start chatting',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Start a New Chat'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
