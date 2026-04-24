import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p2p_messenger/core/utils/responsive.dart';
import 'package:p2p_messenger/models/chat.dart';
import 'package:p2p_messenger/providers/chat_provider.dart';
import 'package:p2p_messenger/providers/connection_provider.dart'
    hide ConnectionState;
import 'package:p2p_messenger/screens/chat/chat_list_screen.dart';
import 'package:p2p_messenger/screens/chat/chat_screen.dart';
import 'package:p2p_messenger/screens/contacts/contacts_screen.dart';
import 'package:p2p_messenger/screens/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Chat? _selectedChat;

  void _onChatSelected(Chat chat) {
    setState(() => _selectedChat = chat);
    context.read<ChatProvider>().setActiveChat(chat.id);

    if (!Responsive.isDesktop(context)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chat: chat),
        ),
      );
    }
  }

  void _onChatStartedFromContacts(String chatId) {
    final chatProvider = context.read<ChatProvider>();
    final chat = chatProvider.chats.where((c) => c.id == chatId).firstOrNull;
    if (chat != null) {
      setState(() {
        _currentIndex = 0;
        _selectedChat = chat;
      });
      chatProvider.setActiveChat(chat.id);

      if (!Responsive.isDesktop(context)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(chat: chat),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final conn = context.watch<ConnectionProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Connection status bar
          if (!conn.isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade700,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Connecting to server...',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ],
      ),
      bottomNavigationBar:
          isDesktop ? null : _buildBottomNav(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Desktop side navigation
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(
              Icons.chat_bubble_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat_rounded),
              label: Text('Chats'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.people_outlined),
              selectedIcon: Icon(Icons.people_rounded),
              label: Text('Contacts'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: Text('Settings'),
            ),
          ],
        ),
        const VerticalDivider(width: 1),

        // Chat list panel
        if (_currentIndex == 0)
          SizedBox(
            width: Responsive.chatListWidth(context),
            child: Column(
              children: [
                _buildChatListHeader(),
                Expanded(
                  child: ChatListScreen(
                    onChatSelected: _onChatSelected,
                    selectedChatId: _selectedChat?.id,
                  ),
                ),
              ],
            ),
          )
        else if (_currentIndex == 1)
          SizedBox(
            width: Responsive.chatListWidth(context),
            child: ContactsScreen(
              onChatStarted: _onChatStartedFromContacts,
            ),
          )
        else
          SizedBox(
            width: Responsive.chatListWidth(context),
            child: const SettingsScreen(),
          ),

        const VerticalDivider(width: 1),

        // Chat detail panel
        Expanded(
          child: _selectedChat != null && _currentIndex == 0
              ? ChatScreen(chat: _selectedChat!)
              : _buildEmptyChatPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    switch (_currentIndex) {
      case 0:
        return Column(
          children: [
            _buildChatListHeader(),
            Expanded(
              child: ChatListScreen(onChatSelected: _onChatSelected),
            ),
          ],
        );
      case 1:
        return ContactsScreen(
          onChatStarted: _onChatStartedFromContacts,
        );
      case 2:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChatListHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Chats',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_square),
                onPressed: () {
                  setState(() => _currentIndex = 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search chats...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a chat to start messaging',
            style: TextStyle(
              fontSize: 16,
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

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.chat_outlined),
          selectedIcon: Icon(Icons.chat_rounded),
          label: 'Chats',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outlined),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Contacts',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}
