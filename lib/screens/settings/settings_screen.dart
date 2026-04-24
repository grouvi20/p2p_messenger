import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF353750)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AvatarWidget(
                      name: user?.displayName ?? '?',
                      imageUrl: user?.avatarUrl,
                      size: 64,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: connection.isConnected
                                    ? const Color(0xFF4CAF50)
                                    : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                connection.isConnected
                                    ? 'Online'
                                    : 'Offline',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: connection.isConnected
                                      ? const Color(0xFF4CAF50)
                                      : Colors.red,
                                ),
                              ),
                            ],
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
                const SizedBox(height: 16),
                // User ID row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.black.withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${user?.id.substring(0, 8) ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (user != null) {
                            Clipboard.setData(
                                ClipboardData(text: user.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('ID copied!'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this ID with friends so they can message you',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

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

          // Connection (collapsible, less prominent)
          _buildSectionTitle(context, 'Connection'),
          ListTile(
            leading: Icon(
              Icons.circle,
              size: 12,
              color: connection.isConnected ? Colors.green : Colors.red,
            ),
            title: const Text('Server Status'),
            subtitle:
                Text(connection.isConnected ? 'Connected' : 'Disconnected'),
          ),
          ListTile(
            leading: const Icon(Icons.dns_rounded),
            title: const Text('Server URL'),
            subtitle: Text(connection.serverUrl),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showEditServer(context),
          ),
          const Divider(),

          // About
          _buildSectionTitle(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_rounded),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
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
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Your name',
            prefixIcon: Icon(Icons.person_rounded),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                auth.updateProfile(displayName: name);
              }
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
