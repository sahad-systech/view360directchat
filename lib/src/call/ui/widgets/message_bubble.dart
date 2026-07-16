import 'package:flutter/material.dart';
import '../../config/call_strings.dart';
import '../../config/call_theme.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final View360CallTheme theme;
  final View360CallStrings strings;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.theme,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isUser ? strings.you : strings.agent,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isUser ? Colors.blue : Colors.purple,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isUser ? theme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(20).copyWith(
                topRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(20),
                topLeft: !isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(20),
              ),
              boxShadow: isUser
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
