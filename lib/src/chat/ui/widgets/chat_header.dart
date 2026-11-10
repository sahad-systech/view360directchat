import 'package:flutter/material.dart';

import '../../../local/local_storage.dart';

/// Top header bar for the View360 chat screen showing agent avatar, online status,
/// title, subtitle, and navigation actions.
class ChatHeader extends StatelessWidget {
  /// Callback fired when the back button is tapped.
  final VoidCallback? onBackPressed;

  /// Callback fired when the exit/close button is tapped.
  final VoidCallback? onClosePressed;

  /// Creates a [ChatHeader] widget.
  const ChatHeader({super.key, this.onBackPressed, this.onClosePressed});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: View360ChatPrefs.isChatIdNullOrEmpty(),
      initialData: true,
      builder: (context, snapshot) {
        final bool isChatIdNullOrEmpty = snapshot.data ?? true;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (onBackPressed != null)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF111827),
                    ),
                    tooltip: 'Back',
                    onPressed: onBackPressed,
                    splashRadius: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                const SizedBox(width: 8),
                // Avatar with online status badge
                const Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF3F4E65),
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Agent title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isChatIdNullOrEmpty) ...[
                        const Text(
                          'Agent',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      const Text(
                        'Active Support',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isChatIdNullOrEmpty && onClosePressed != null)
                  IconButton(
                    icon: const Icon(
                      Icons.exit_to_app_rounded,
                      size: 24,
                      color: Color(0xFF1F2937),
                    ),
                    tooltip: 'Close',
                    onPressed: onClosePressed,
                    splashRadius: 22,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
