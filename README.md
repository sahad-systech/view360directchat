# view360directchat

A comprehensive Flutter package for integrating **View360's real-time chat & AI voice call solutions** into Flutter applications.

`view360directchat` enables real-time customer support chat, REST-based messaging API, file attachment uploads, automatic push notifications via Firebase Cloud Messaging (FCM), local session persistence, and an interactive **LiveKit-powered AI Voice Call page**.

## Quick Start

```dart
import 'package:view360directchat/view360directchat.dart';

// 1. Initialize once
await View360.init(View360Config(
  baseUrl: 'https://chat.view360.cx',
  appId: 'YOUR_APP_ID',
  customer: const View360Customer(name: 'John Doe'), // optional default
));

// 2. Chat or call without repeating configuration
await View360.chat.createChatSession(chatContent: 'Hello!');
// or
View360.openCall(context); // provided call settings are configured
```

## Key Features

- **Single Entry Point (`View360`)** — Initialize once and easily access chat and calls.
- **Real-time Socket Connection (`SocketManager`)** — Instant bidirectional web-socket communication using `socket_io_client`.
- **Chat Session Management (`ChatService`)** — Easily register chat sessions, send text messages, handle queuing, and close sessions.
- **Multipart Attachment Uploads** — Send images (`.jpg`, `.png`, `.gif`), documents (`.pdf`, `.xlsx`, `.csv`), and videos (`.mp4`).
- **Chat History Retrieval** — Fetch past conversation messages with timestamps and sender identifiers.
- **FCM Push Notification Sync** — Automatically registers Firebase Cloud Messaging tokens with View360 servers.
- **Persistent Local Storage (`View360ChatPrefs`)** — Automatically saves customer IDs, chat IDs, and queue statuses using `shared_preferences`.
- **AI Voice Calling (`View360CallPage`)** — Complete pre-built UI and service (`LivekitCallService`) for real-time voice conversations powered by LiveKit WebRTC, live transcription streaming, and post-call feedback ratings.

## Advanced / Manual Setup

### 1. Initialize Real-Time Socket Manager

The `SocketManager` singleton connects to the View360 WebSocket server (`/chatsocket.io` namespace) and handles events such as incoming messages, agent join notifications, and session closures.

```dart
import 'package:view360directchat/view360directchat.dart';

final socketManager = SocketManager();

socketManager.connect(
  baseUrl: 'https://your-view360-domain.com',
  onConnected: () {
    print('Socket connected successfully!');
  },
  onMessage: ({
    required String content,
    List<String>? filePaths,
    required dynamic response,
    required String senderType,
    required String createdAt,
  }) {
    print('Message from $senderType: $content');
    if (filePaths != null && filePaths.isNotEmpty) {
      print('Attachments: $filePaths');
    }
  },
  onAgentJoin: ({required String name}) {
    print('Agent connected: $name');
  },
  onAgentClose: () {
    print('Agent closed the chat session.');
  },
);

// To disconnect when no longer needed:
// socketManager.disconnect();
```

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
    print('Customer placed in queue. Waiting for an available agent.');
  } else if (response.isOutOfOfficeTime) {
    print('Session created, but currently out of office hours.');
  } else {
    print('Chat session established!');
  }
} else {
  print('Error starting chat: ${response.message}');
}
```

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
  print('Message delivered!');
} else {
  print('Message failed to send: ${sendResponse.error}');
}
```

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
  print('Failed to load messages: ${history.error}');
}
```

### 5. Close Chat Session

End the chat session on the server and clear locally cached credentials:

```dart
await chatService.closeChat();
print('Chat session ended and local storage cleared.');
```

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
        onCallStarted: () => print('Voice call started'),
        onCallEnded: () => print('Voice call ended'),
        onRatingSubmitted: (rating, feedback) {
          print('Customer rating: $rating, feedback: $feedback');
        },
        onError: (error) => print('Call error: $error'),
      ),
    ),
  );
}
```

## Platform Configuration

### Android Setup

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

### iOS Setup

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
