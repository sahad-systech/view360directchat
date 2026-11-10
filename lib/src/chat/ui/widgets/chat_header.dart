import 'package:flutter/material.dart';

/// Top header bar for the View360 chat screen showing agent avatar, online status,
/// title, subtitle, and navigation actions.
class ChatHeader extends StatelessWidget {
  /// Callback fired when the back button is tapped.
  final VoidCallback? onBackPressed;

  /// Callback fired when the exit/close button is tapped.
  final VoidCallback? onClosePressed;

  /// Whether the online indicator badge is displayed.
  final bool isOnline;

  /// Creates a [ChatHeader] widget.
  const ChatHeader({
    super.key,
    this.onBackPressed,
    this.onClosePressed,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
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
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            const SizedBox(width: 8),
            // Avatar with online status badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(
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
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Agent title and subtitle
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Agent',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
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
            if (onClosePressed != null)
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
  }
}
