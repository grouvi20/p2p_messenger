import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p2p_messenger/providers/auth_provider.dart';
import 'package:p2p_messenger/providers/connection_provider.dart';
import 'package:p2p_messenger/providers/theme_provider.dart';
import 'package:p2p_messenger/widgets/avatar_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final connection = context.watch<ConnectionProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile section
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                AvatarWidget(
                  name: user?.displayName ?? '?',
                  imageUrl: user?.avatarUrl,
                  size: 72,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user?.username ?? 'unknown'}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _showEditProfile(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Connection status
          _buildSectionTitle(context, 'Connection'),
          ListTile(
            leading: Icon(
              Icons.circle,
              size: 12,
              color: connection.isConnected ? Colors.green : Colors.red,
            ),
            title: const Text('Server Status'),
            subtitle: Text(connection.isConnected ? 'Connected' : 'Disconnected'),
          ),
          ListTile(
            leading: const Icon(Icons.dns_rounded),
            title: const Text('Server URL'),
            subtitle: Text(connection.serverUrl),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showEditServer(context),
          ),
          const Divider(),

          // Appearance
          _buildSectionTitle(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(theme.themeMode)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemePicker(context),
          ),
          const Divider(),

          // About
          _buildSectionTitle(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_rounded),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('Architecture'),
            subtitle: const Text('P2P with WebSocket signaling'),
            onTap: () => _showArchInfo(context),
          ),
          const Divider(),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemePicker(BuildContext context) {
    final theme = context.read<ThemeProvider>();
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(
                  mode == theme.themeMode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: mode == theme.themeMode
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(_themeLabel(mode)),
                onTap: () {
                  theme.setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(
      text: auth.currentUser?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Display Name',
            prefixIcon: Icon(Icons.person_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              auth.updateProfile(displayName: controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditServer(BuildContext context) {
    final conn = context.read<ConnectionProvider>();
    final controller = TextEditingController(text: conn.serverUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'ws://host:port/ws',
            prefixIcon: Icon(Icons.dns_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              conn.updateServerUrl(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showArchInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('P2P Architecture'),
        content: const Text(
          'Messages are routed through a lightweight signaling server using '
          'WebSocket connections. The server relays messages between peers '
          'and queues them when a peer is offline.\n\n'
          'Key features:\n'
          '- Real-time message delivery via WebSocket\n'
          '- Typing indicators\n'
          '- Read receipts\n'
          '- Online/offline status\n'
          '- Offline message queuing\n'
          '- Local notifications',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ConnectionProvider>().disconnect();
              context.read<AuthProvider>().logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
