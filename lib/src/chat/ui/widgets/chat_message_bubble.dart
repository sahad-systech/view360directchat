import 'package:flutter/material.dart';
import '../../config/chat_strings.dart';
import '../../config/chat_theme.dart';
import '../../model/chat_ui_message.dart';

/// Renders a single chat item, which can be an outgoing user bubble, an incoming
/// agent bubble with an avatar, or a centered system notification pill.
class ChatMessageBubble extends StatelessWidget {
  /// The chat message model to render.
  final View360ChatMessage message;

  /// Theme styling for bubble colors and typography.
  final View360ChatTheme theme;

  /// Localized labels and strings.
  final View360ChatStrings strings;

  /// Creates a [ChatMessageBubble] widget.
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.theme,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _buildSystemPill();
    }

    if (message.isUser) {
      return _buildUserBubble(context);
    }

    return _buildAgentBubble(context);
  }

  Widget _buildSystemPill() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: theme.systemPillColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: theme.systemPillTextColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: theme.userBubbleColor,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: theme.userTextColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            ),
            if (message.time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  top: 4.0,
                  right: 4.0,
                  bottom: 4.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.time,
                      style: TextStyle(
                        color: theme.timestampColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (message.isSeen) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 15,
                        color: theme.readReceiptColor,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentBubble(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.agentBubbleAvatarColor,
            child: Text(
              strings.agentInitial,
              style: TextStyle(
                color: theme.agentBubbleAvatarTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                decoration: BoxDecoration(
                  color: theme.agentBubbleColor,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: theme.agentTextColor,
                    fontSize: 14.0,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (message.time.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4.0,
                    top: 4.0,
                    bottom: 4.0,
                  ),
                  child: Text(
                    message.time,
                    style: TextStyle(
                      color: theme.timestampColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}