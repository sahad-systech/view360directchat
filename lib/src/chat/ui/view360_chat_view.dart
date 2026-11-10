import 'package:flutter/material.dart';
import '../../local/local_storage.dart';
import '../../socket/socket_managet.dart';
import '../../view360.dart';
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
  bool _isLoading = true;
  bool _isChatIdNullOrEmpty = true;

  @override
  void initState() {
    super.initState();
    _initializeMessages();
    _fetchMessages();
    _ensureSocketConnected();
  }

  void _ensureSocketConnected() {
    if (!View360.isInitialized) return;

    SocketManager().connect(
      onMessage:
          ({
            required String content,
            List<String>? filePaths,
            required dynamic response,
            required String senderType,
            required String createdAt,
          }) {
            if (mounted && content.isNotEmpty) {
              setState(() {
                _messages.add(View360ChatMessage.agent(content: content));
              });
              _scrollToBottom();
            }
          },
      onAgentJoin: ({required String name}) {
        if (mounted) {
          _fetchMessages();
        }
      },
      onAgentClose: () {
        if (mounted) {
          setState(() {});
        }
      },
      onConnected: () {
        debugPrint('View360ChatView: Socket connection established.');
      },
    );
  }

  void _initializeMessages() {
    if (widget.initialMessages != null) {
      _messages.addAll(widget.initialMessages!);
    }
  }

  Future<void> _fetchMessages() async {
    final bool isNullOrEmpty = await View360ChatPrefs.isChatIdNullOrEmpty();
    if (!mounted) return;

    if (isNullOrEmpty) {
      setState(() {
        _isChatIdNullOrEmpty = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isChatIdNullOrEmpty = false;
    });

    if (!View360.isInitialized) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await View360.chat.fetchMessages();
      if (!mounted) return;
      if (response.success) {
        setState(() {
          _messages.clear();
          _messages.addAll(
            response.messages.map(View360ChatMessage.fromChatMessage),
          );
          _isChatIdNullOrEmpty = false;
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _handleSendMessage(String text) async {
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

    try {
      if (View360.isInitialized) {
        final bool isChatIdEmpty = await View360ChatPrefs.isChatIdNullOrEmpty();
        if (isChatIdEmpty) {
          await View360.chat.createChatSession(chatContent: trimmed);
        } else {
          await View360.chat.sendChatMessage(chatContent: trimmed);
        }
      }
    } catch (e) {
      debugPrint('Error sending chat message: $e');
    }
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF4E37D3),
                    ),
                  )
                : (_isChatIdNullOrEmpty && _messages.isEmpty)
                ? const Center(
                    child: Text(
                      'chat is not created',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : ListView.builder(
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
