import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p2p_messenger/app.dart';
import 'package:p2p_messenger/providers/auth_provider.dart';
import 'package:p2p_messenger/providers/chat_provider.dart';
import 'package:p2p_messenger/providers/connection_provider.dart';
import 'package:p2p_messenger/providers/theme_provider.dart';
import 'package:p2p_messenger/services/media_service.dart';
import 'package:p2p_messenger/services/notification_service.dart';
import 'package:p2p_messenger/services/p2p_service.dart';
import 'package:p2p_messenger/services/signaling_service.dart';
import 'package:p2p_messenger/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  await NotificationService().init();

  final signalingService = SignalingService();
  final p2pService = P2PService(signalingService);
  final mediaService = MediaService('http://localhost:8080');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectionProvider(
            signalingService,
            p2pService,
            storageService,
          ),
        ),
        Provider<MediaService>.value(value: mediaService),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider?>(
          create: (_) => null,
          update: (_, auth, previous) {
            if (!auth.isLoggedIn) return null;
            if (previous != null) return previous;
            return ChatProvider(
              p2pService,
              storageService,
              mediaService,
              auth.currentUser!.id,
            );
          },
        ),
      ],
      child: const MessengerApp(),
    ),
  );
}
