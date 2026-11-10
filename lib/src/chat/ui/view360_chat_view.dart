import 'package:flutter/material.dart';
import '../model/chat_ui_message.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_message_bubble.dart';

/// Embeddable chat view widget displaying the View360 direct chat conversation.
class View360ChatView extends StatefulWidget {
  /// Initial messages to populate the chat. If omitted,
  /// defaults to [View360ChatMessage.defaultSampleMessages].
  final List<View360ChatMessage>? initialMessages;

  /// Whether to display the top agent header bar.
  final bool showHeader;

  /// Callback fired when the user sends a message.
  final void Function(String text)? onSendMessage;

  /// Callback fired when the back button is pressed in the header.
  final VoidCallback? onBackPressed;

  /// Callback fired when the close/exit button is pressed in the header.
  final VoidCallback? onClosePressed;

  /// Creates a [View360ChatView] widget.
  const View360ChatView({
    super.key,
    this.initialMessages,
    this.showHeader = true,
    this.onSendMessage,
    this.onBackPressed,
    this.onClosePressed,
  });

  @override
  State<View360ChatView> createState() => _View360ChatViewState();
}

class _View360ChatViewState extends State<View360ChatView> {
  final List<View360ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  void _initializeMessages() {
    if (widget.initialMessages != null) {
      _messages.addAll(widget.initialMessages!);
    } else {
      _messages.addAll(View360ChatMessage.defaultSampleMessages);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = View360ChatMessage.user(
      content: trimmed,
      isSeen: false,
    );

    setState(() {
      _messages.add(userMessage);
    });
    _scrollToBottom();

    widget.onSendMessage?.call(trimmed);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFD),
      child: Column(
        children: [
          if (widget.showHeader)
            ChatHeader(
              onBackPressed: widget.onBackPressed,
              onClosePressed: widget.onClosePressed,
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatMessageBubble(message: message);
              },
            ),
          ),
          ChatInputBar(onSend: _handleSendMessage),
        ],
      ),
    );
  }
}
