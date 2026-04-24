# P2P Messenger

A cross-platform peer-to-peer messenger built with Flutter, featuring real-time messaging via WebSocket signaling, Telegram-style UI, and desktop adaptive layout.

## Features

- **P2P Messaging** - Messages routed through a lightweight signaling server with offline queuing
- **Real-time Communication** - WebSocket-based signaling for instant message delivery
- **Telegram-style UI** - Rounded, modern design with smooth animations
- **Desktop Adaptive** - Side-by-side layout with navigation rail on desktop, bottom nav on mobile
- **Dark/Light Theme** - Full theme support with system detection
- **Typing Indicators** - Real-time typing status
- **Read Receipts** - Message delivery and read confirmations
- **Online Status** - Live online/offline peer tracking
- **Local Notifications** - Message notifications when app is in background
- **Offline Message Queue** - Server queues messages for offline peers

## Architecture

```
+------------------+     WebSocket     +------------------+
|   Flutter App    | <===============> | Signaling Server |
|   (Client A)     |                   |   (Dart/Shelf)   |
+------------------+                   +------------------+
                                              ^
                                              | WebSocket
                                              v
                                       +------------------+
                                       |   Flutter App    |
                                       |   (Client B)     |
                                       +------------------+
```

Messages are relayed through the signaling server via WebSocket connections. The server handles:
- User registration & online status broadcasting
- Message relay between connected peers
- Offline message queuing & delivery on reconnect
- Typing indicator & read receipt forwarding

## Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Dart SDK 3.x+

### Run the Signaling Server

```bash
cd server
dart pub get
dart run bin/server.dart
```

The server starts on `http://localhost:8080` by default. Pass a port number as argument to change:
```bash
dart run bin/server.dart 9090
```

### Run the Flutter App

```bash
# Install dependencies
flutter pub get

# Run on Linux desktop
flutter run -d linux

# Run on Web
flutter run -d chrome

# Run on Android
flutter run -d android
```

### Connect Two Clients

1. Start the signaling server
2. Launch the app on two devices/windows
3. Enter different usernames on each client
4. Set the server URL to point to your signaling server (default: `ws://localhost:8080`)
5. Add a contact using the peer's User ID
6. Start chatting!

## Project Structure

```
p2p_messenger/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # MaterialApp configuration
│   ├── core/
│   │   ├── theme/app_theme.dart  # Light/dark theme definitions
│   │   ├── constants/            # App-wide constants
│   │   └── utils/responsive.dart # Responsive layout helpers
│   ├── models/                   # Data models (User, Message, Chat)
│   ├── services/
│   │   ├── signaling_service.dart    # WebSocket signaling client
│   │   ├── p2p_service.dart          # P2P message handling
│   │   ├── notification_service.dart # Local notifications
│   │   └── storage_service.dart      # Local data persistence
│   ├── providers/                # State management (Provider)
│   ├── screens/                  # UI screens
│   │   ├── auth/                 # Login screen
│   │   ├── home/                 # Main layout with adaptive design
│   │   ├── chat/                 # Chat list & chat detail
│   │   ├── contacts/             # Contact management
│   │   └── settings/             # App settings & profile
│   └── widgets/                  # Reusable UI components
│       ├── avatar_widget.dart    # User avatar with online indicator
│       ├── message_bubble.dart   # Chat message bubble
│       ├── chat_tile.dart        # Chat list item
│       └── chat_input.dart       # Message input field
├── server/
│   └── bin/server.dart           # Dart signaling server
└── README.md
```

## Desktop Layout

On screens wider than 1024px, the app displays:
- **Navigation Rail** on the left with Chats, Contacts, Settings
- **Chat List Panel** (380px) with search
- **Chat Detail Panel** filling remaining space

On mobile/tablet, it uses standard navigation with bottom navigation bar.

## License

MIT
