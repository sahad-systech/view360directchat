import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../socket/socket_managet.dart';
import '../config/chat_strings.dart';
import '../config/chat_theme.dart';
import '../model/chat_ui_message.dart';
import 'view360_chat_view.dart';

/// Full-screen chat page widget displaying the View360 direct chat interface.
///
/// Wraps [View360ChatView] in a [Scaffold] with appropriate status bar and navigation
/// handling. Can be pushed directly onto the navigator stack.
class View360ChatPage extends StatelessWidget {
  /// Theme configuration for colors and typography.
  final View360ChatTheme theme;

  /// Localized labels and placeholder strings.
  final View360ChatStrings strings;

  /// Initial messages to display in the conversation.
  final List<View360ChatMessage>? initialMessages;

  /// Whether to auto-connect to real-time events and fetch session history.
  final bool autoConnect;

  /// Optional custom [ChatService] instance for API calls.
  final ChatService? chatService;

  /// Optional custom [SocketManager] instance for real-time events.
  final SocketManager? socketManager;

  /// Callback fired when user sends a message.
  final void Function(String text)? onSendMessage;

  /// Callback fired when the back button is pressed. Defaults to `Navigator.of(context).pop()`.
  final VoidCallback? onBackPressed;

  /// Callback fired when the close/exit button is pressed.
  final VoidCallback? onClosePressed;

  /// Creates a [View360ChatPage] widget.
  const View360ChatPage({
    super.key,
    this.theme = const View360ChatTheme(),
    this.strings = const View360ChatStrings(),
    this.initialMessages,
    this.autoConnect = true,
    this.chatService,
    this.socketManager,
    this.onSendMessage,
    this.onBackPressed,
    this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        top: false,
        child: View360ChatView(
          theme: theme,
          strings: strings,
          initialMessages: initialMessages,
          autoConnect: autoConnect,
          chatService: chatService,
          socketManager: socketManager,
          onSendMessage: onSendMessage,
          onBackPressed:
              onBackPressed ?? () => Navigator.of(context).maybePop(),
          onClosePressed:
              onClosePressed ?? () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
