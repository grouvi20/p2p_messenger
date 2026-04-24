import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p2p_messenger/core/theme/app_theme.dart';
import 'package:p2p_messenger/providers/auth_provider.dart';
import 'package:p2p_messenger/providers/chat_provider.dart';
import 'package:p2p_messenger/providers/connection_provider.dart';
import 'package:p2p_messenger/providers/theme_provider.dart';
import 'package:p2p_messenger/screens/auth/login_screen.dart';
import 'package:p2p_messenger/screens/home/home_screen.dart';

class MessengerApp extends StatelessWidget {
  const MessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'P2P Messenger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isLoggedIn) {
            return const LoginScreen();
          }

          // Connect on login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final conn = context.read<ConnectionProvider>();
            if (!conn.isConnected) {
              conn.connect(auth.currentUser!.id);
            }
          });

          // Re-provide ChatProvider? as non-nullable ChatProvider
          // so downstream consumers can use context.read<ChatProvider>()
          final chatProvider = context.watch<ChatProvider?>();
          if (chatProvider == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return ChangeNotifierProvider<ChatProvider>.value(
            value: chatProvider,
            child: const HomeScreen(),
          );
        },
      ),
    );
  }
}
