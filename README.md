# 📦 view360directchat (view360_chat)

A comprehensive Flutter package for integrating **View360's real-time chat & AI voice call solutions** into Flutter applications.

`view360directchat` enables real-time customer support chat, REST-based messaging API, file attachment uploads, automatic push notifications via Firebase Cloud Messaging (FCM), local session persistence, and an interactive **LiveKit-powered AI Voice Call page**.

---

## 🌟 Key Features

- 🔌 **Real-time Socket Connection (`SocketManager`)** — Instant bidirectional web-socket communication using `socket_io_client`.
- 💬 **Chat Session Management (`ChatService`)** — Easily register chat sessions, send text messages, handle queuing, and close sessions.
- 📎 **Multipart Attachment Uploads** — Send images (`.jpg`, `.png`, `.gif`), documents (`.pdf`, `.xlsx`, `.csv`), and videos (`.mp4`).
- 📜 **Chat History Retrieval** — Fetch past conversation messages with timestamps and sender identifiers.
- 📲 **FCM Push Notification Sync** — Automatically registers Firebase Cloud Messaging tokens with View360 servers.
- 💾 **Persistent Local Storage (`View360ChatPrefs`)** — Automatically saves customer IDs, chat IDs, and queue statuses using `shared_preferences`.
- 🎙️ **AI Voice Calling (`View360CallPage`)** — Complete pre-built UI and service (`LivekitCallService`) for real-time voice conversations powered by LiveKit WebRTC, live transcription streaming, and post-call feedback ratings.

---

## 📁 Package Architecture

```
lib/
├── view360directchat.dart       # Main package barrel export file
└── src/
    ├── api/
    │   └── api_service.dart      # REST API client (ChatService)
    ├── socket/
    │   └── socket_managet.dart   # Socket.IO connection manager (SocketManager)
    ├── local/
    │   └── local_storage.dart    # Shared preferences helper (View360ChatPrefs)
    ├── model/
    │   ├── chat_response.dart    # Session registration models
    │   ├── chat_list_response.dart # Chat history and message models
    │   ├── sending_response.dart # Message delivery responses
    │   └── storage_pre_model.dart# Preferences data model
    ├── helper/
    │   └── function.dart         # Utility functions (MIME detection, FCM helper)
    └── call/                     # AI Voice Call Sub-system
        ├── config/               # Call configs, themes, and localized strings
        ├── model/                # Token & transcript data models
        ├── service/              # LiveKit WebRTC call state engine
        └── ui/                   # Voice call screen & UI state widgets
```

---

## 💻 Installation & Platform Configuration

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  view360directchat: ^1.0.0
```

### 🤖 Android Setup

In `android/app/src/main/AndroidManifest.xml`, ensure the following permissions are present:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required permissions for LiveKit Voice Calls -->
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>

    <application>
        ...
    </application>
</manifest>
```

### 🍏 iOS Setup

Add the required usage descriptions and background modes to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for AI voice calls.</string>

<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>

<key>NSUserTrackingUsageDescription</key>
<string>We need your permission to send notifications for chat updates.</string>
```

---

## 🚀 Usage Guide

### 1. Initialize Real-Time Socket Manager

The `SocketManager` singleton connects to the View360 WebSocket server (`/chatsocket.io` namespace) and handles events such as incoming messages, agent join notifications, and session closures.

```dart
import 'package:view360directchat/view360directchat.dart';

final socketManager = SocketManager();

socketManager.connect(
  baseUrl: 'https://your-view360-domain.com',
  onConnected: () {
    print('✅ Socket connected successfully!');
  },
  onMessage: ({
    required String content,
    List<String>? filePaths,
    required dynamic response,
    required String senderType,
    required String createdAt,
  }) {
    print('📩 Message from $senderType: $content');
    if (filePaths != null && filePaths.isNotEmpty) {
      print('📎 Attachments: $filePaths');
    }
  },
  onAgentJoin: ({required String name}) {
    print('👤 Agent connected: $name');
  },
  onAgentClose: () {
    print('🔴 Agent closed the chat session.');
  },
);

// To disconnect when no longer needed:
// socketManager.disconnect();
```

---

### 2. Register & Create a Chat Session

Instantiate `ChatService` with your View360 base URL and App ID to start a conversation.

```dart
import 'package:view360directchat/view360directchat.dart';

final chatService = ChatService(
  baseUrl: 'https://your-view360-domain.com',
  appId: 'YOUR_VIEW360_APP_ID',
);

final response = await chatService.createChatSession(
  chatContent: 'Hello! I need help with my account.',
  customerName: 'John Doe',
  customerEmail: 'john.doe@example.com',
  customerPhone: '+1234567890',
  fetchFCMToken: true, // Automatically fetches and updates FCM token
);

if (response.success) {
  if (response.isInQueue) {
    print('⏳ Customer placed in queue. Waiting for an available agent.');
  } else if (response.isOutOfOfficeTime) {
    print('🌙 Session created, but currently out of office hours.');
  } else {
    print('✅ Chat session established!');
  }
} else {
  print('❌ Error starting chat: ${response.message}');
}
```

---

### 3. Send Chat Messages & Attachments

Send text messages along with optional file attachments (images, PDFs, videos, spreadsheets).

```dart
final sendResponse = await chatService.sendChatMessage(
  chatContent: 'Here is the requested invoice.',
  filePath: [
    '/path/to/invoice.pdf',
    '/path/to/screenshot.png',
  ],
);

if (sendResponse.status) {
  print('✅ Message delivered!');
} else {
  print('❌ Message failed to send: ${sendResponse.error}');
}
```

#### Supported Attachment Types
- **Images**: `.jpg`, `.jpeg`, `.png`, `.gif`
- **Documents**: `.pdf`, `.xlsx`, `.csv`
- **Video**: `.mp4`

---

### 4. Fetch Conversation History

Retrieve the complete chat history for the active session:

```dart
final history = await chatService.fetchMessages();

if (history.success) {
  for (var msg in history.messages) {
    print('[${msg.createdAt}] ${msg.senderType}: ${msg.content}');
    if (msg.files.isNotEmpty) {
      print('  Files: ${msg.files}');
    }
  }
} else {
  print('❌ Failed to load messages: ${history.error}');
}
```

---

### 5. Close Chat Session

End the chat session on the server and clear locally cached credentials:

```dart
await chatService.closeChat();
print('Chat session ended and local storage cleared.');
```

---

### 6. Local Session Storage (`View360ChatPrefs`)

Inspect or clear saved customer preferences manually if needed:

```dart
// Retrieve stored session model
View360ChatPrefsModel prefModel = await View360ChatPrefs.getString();
print('Customer ID: ${prefModel.customerId}');
print('Chat ID: ${prefModel.chatId}');
print('In Queue: ${prefModel.isInQueue}');

// Clear session
await View360ChatPrefs.remove();
```

---

### 7. AI Voice Call Feature (`View360CallPage`)

Integrate an interactive, full-screen AI voice calling experience powered by LiveKit WebRTC:

```dart
import 'package:flutter/material.dart';
import 'package:view360directchat/view360directchat.dart';

void openVoiceCall(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => View360CallPage(
        config: const View360CallConfig(
          tokenUrl: 'https://ai.view360.cx/api/token',
          sdkId: 'YOUR_SDK_ID',
          apiKey: 'YOUR_API_KEY',
          livekitUrl: 'wss://livekit.view360.cx',
          notificationTitle: 'Active AI Voice Call',
          notificationText: 'Voice call is in progress...',
        ),
        userName: 'John Doe',
        userPhone: '+1234567890',
        userEmail: 'john.doe@example.com',
        // Optional Customizations
        theme: View360CallTheme(
          primaryColor: Colors.deepPurple,
        ),
        strings: const View360CallStrings(
          agentName: 'View360 Voice Assistant',
          haveAQuestion: 'Need instant help?',
        ),
        onCallStarted: () => print('🎙️ Voice call started'),
        onCallEnded: () => print('📞 Voice call ended'),
        onRatingSubmitted: (rating, feedback) {
          print('⭐ Customer rating: $rating, feedback: $feedback');
        },
        onError: (error) => print('⚠️ Call error: $error'),
      ),
    ),
  );
}
```

---

## 🛠️ API Reference Summary

| Module | Core Class | Main Purpose |
| :--- | :--- | :--- |
| **API** | [`ChatService`](file:///Users/sahadmp/view360directchat/lib/src/api/api_service.dart) | Manages REST endpoints for registration, sending messages/files, history, FCM tokens, and session closing. |
| **Socket** | [`SocketManager`](file:///Users/sahadmp/view360directchat/lib/src/socket/socket_managet.dart) | Singleton socket client handling real-time incoming messages, agent assignment, and disconnect events. |
| **Storage** | [`View360ChatPrefs`](file:///Users/sahadmp/view360directchat/lib/src/local/local_storage.dart) | Manages `SharedPreferences` persistence for customer ID, chat ID, and queue status. |
| **Call UI** | [`View360CallPage`](file:///Users/sahadmp/view360directchat/lib/src/call/ui/view360_call_page.dart) | Flutter widget rendering the AI Voice Call interface with live transcription bubbles and call controls. |
| **Call Engine** | [`LivekitCallService`](file:///Users/sahadmp/view360directchat/lib/src/call/service/livekit_call_service.dart) | `ChangeNotifier` state engine controlling WebRTC connection, mute/speaker toggles, and rating submissions. |
| **Call Config** | [`View360CallConfig`](file:///Users/sahadmp/view360directchat/lib/src/call/config/call_config.dart) | Configuration holder for token URLs, LiveKit WebSocket URLs, SDK IDs, and API keys. |

---

## 📄 License

This package is proprietary software maintained by **View360 (Systech)**.
For inquiries, visit [view360.cx](https://view360.cx).

