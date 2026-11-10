import 'package:flutter/material.dart';
import '../model/chat_ui_message.dart';
import 'view360_chat_view.dart';

/// Full-screen chat page widget displaying the View360 direct chat interface.
///
/// Wraps [View360ChatView] in a [Scaffold] with appropriate status bar and navigation
/// handling. Can be pushed directly onto the navigator stack.
class View360ChatPage extends StatelessWidget {
  /// Initial messages to display in the conversation.
  final List<View360ChatMessage>? initialMessages;

  /// Callback fired when user sends a message.
  final void Function(String text)? onSendMessage;

  /// Callback fired when the back button is pressed. Defaults to `Navigator.of(context).pop()`.
  final VoidCallback? onBackPressed;

  /// Callback fired when the close/exit button is pressed.
  final VoidCallback? onClosePressed;

  /// Creates a [View360ChatPage] widget.
  const View360ChatPage({
    super.key,
    this.initialMessages,
    this.onSendMessage,
    this.onBackPressed,
    this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFD),
      body: SafeArea(
        top: false,
        child: View360ChatView(
          initialMessages: initialMessages,
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
