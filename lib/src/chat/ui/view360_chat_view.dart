import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../socket/socket_managet.dart';
import '../../view360.dart';
import '../config/chat_strings.dart';
import '../config/chat_theme.dart';
import '../model/chat_ui_message.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_message_bubble.dart';

/// Embeddable chat view widget displaying the View360 direct chat conversation.
///
/// Can run in standalone/preview mode with sample or custom messages, or fully
/// connected with real-time socket events and backend REST API synchronization.
class View360ChatView extends StatefulWidget {
  /// Theme styling for bubbles, background, and inputs.
  final View360ChatTheme theme;

  /// Localized labels and placeholder strings.
  final View360ChatStrings strings;

  /// Initial messages to populate the chat. If omitted and not connected,
  /// defaults to [View360ChatMessage.defaultSampleMessages].
  final List<View360ChatMessage>? initialMessages;

  /// Whether to display the top agent header bar.
  final bool showHeader;

  /// Whether to automatically connect to [SocketManager] and load message history
  /// from [ChatService] if [View360.isInitialized].
  final bool autoConnect;

  /// Optional custom [ChatService] instance for API communication.
  final ChatService? chatService;

  /// Optional custom [SocketManager] instance for real-time events.
  final SocketManager? socketManager;

  /// Callback fired when the user sends a message.
  final void Function(String text)? onSendMessage;

  /// Callback fired when the back button is pressed in the header.
  final VoidCallback? onBackPressed;

  /// Callback fired when the close/exit button is pressed in the header.
  final VoidCallback? onClosePressed;

  /// Creates a [View360ChatView] widget.
  const View360ChatView({
    super.key,
    this.theme = const View360ChatTheme(),
    this.strings = const View360ChatStrings(),
    this.initialMessages,
    this.showHeader = true,
    this.autoConnect = true,
    this.chatService,
    this.socketManager,
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
  bool _isConnecting = false;

  ChatService? get _effectiveChatService {
    if (widget.chatService != null) return widget.chatService;
    return View360.isInitialized ? View360.chat : null;
  }

  SocketManager? get _effectiveSocketManager {
    if (widget.socketManager != null) return widget.socketManager;
    return View360.isInitialized ? View360.socket : null;
  }

  @override
  void initState() {
    super.initState();
    _initializeMessages();
    if (widget.autoConnect) {
      _setupConnection();
    }
  }

  void _initializeMessages() {
    if (widget.initialMessages != null) {
      _messages.addAll(widget.initialMessages!);
    } else {
      _messages.addAll(View360ChatMessage.defaultSampleMessages);
    }
  }

  Future<void> _setupConnection() async {
    final chatService = _effectiveChatService;
    final socket = _effectiveSocketManager;

    if (chatService == null && socket == null) {
      return;
    }

    setState(() => _isConnecting = true);

    try {
      // Setup real-time socket listener
      if (socket != null) {
        socket.onMessageReceived =
            ({
              required String content,
              List<String>? filePaths,
              required dynamic response,
              required String senderType,
              required String createdAt,
            }) {
              if (!mounted) return;
              final isUser = senderType.toLowerCase() == 'customer';
              setState(() {
                _messages.add(
                  View360ChatMessage(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    content: content,
                    isUser: isUser,
                    isSystem: senderType.toLowerCase() == 'system',
                    time: View360ChatMessage.parseTimeString(createdAt),
                    isSeen: true,
                    files: filePaths ?? const [],
                  ),
                );
              });
              _scrollToBottom();
            };

        socket.onAgentClose = () {
          if (!mounted) return;
          setState(() {
            _messages.add(
              View360ChatMessage.system(
                content: 'Chat session was ended by the agent.',
              ),
            );
          });
          _scrollToBottom();
        };
      }

      // Load conversation history from API
      if (chatService != null) {
        final history = await chatService.fetchMessages();
        if (history.messages.isNotEmpty && mounted) {
          setState(() {
            _messages.clear();
            _messages.add(
              View360ChatMessage.system(
                content: widget.strings.sessionCreatedText,
              ),
            );
            for (final msg in history.messages) {
              _messages.add(View360ChatMessage.fromChatMessage(msg));
            }
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      // Keep existing sample or loaded messages if network fails
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
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

    final chatService = _effectiveChatService;
    if (chatService != null) {
      try {
        final res = await chatService.sendChatMessage(chatContent: trimmed);
        if (res.status && mounted) {
          final index = _messages.indexWhere((m) => m.id == userMessage.id);
          if (index != -1) {
            setState(() {
              _messages[index] = View360ChatMessage.user(
                id: userMessage.id,
                content: userMessage.content,
                time: userMessage.time,
                isSeen: true,
              );
            });
          }
        }
      } catch (_) {
        // Retain message locally
      }
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
      color: widget.theme.backgroundColor,
      child: Column(
        children: [
          if (widget.showHeader)
            ChatHeader(
              theme: widget.theme,
              strings: widget.strings,
              onBackPressed: widget.onBackPressed,
              onClosePressed: widget.onClosePressed,
            ),
          if (_isConnecting)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.theme.primaryColor.withValues(alpha: 0.4),
              ),
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
                return ChatMessageBubble(
                  message: message,
                  theme: widget.theme,
                  strings: widget.strings,
                );
              },
            ),
          ),
          ChatInputBar(
            theme: widget.theme,
            strings: widget.strings,
            onSend: _handleSendMessage,
          ),
        ],
      ),
    );
  }
}