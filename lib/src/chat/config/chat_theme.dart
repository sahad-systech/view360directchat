import 'package:flutter/material.dart';

/// Styling and theme configuration for View360 Chat UI components.
class View360ChatTheme {
  /// Primary theme color used for customer bubbles, accents, and icons.
  final Color primaryColor;

  /// Background color of the entire chat viewport.
  final Color backgroundColor;

  /// Background color of the top app bar/header.
  final Color headerBackgroundColor;

  /// Background color for the customer/user outgoing message bubbles.
  final Color userBubbleColor;

  /// Text color for the customer/user outgoing message bubbles.
  final Color userTextColor;

  /// Background color for the agent/incoming message bubbles.
  final Color agentBubbleColor;

  /// Text color for the agent/incoming message bubbles.
  final Color agentTextColor;

  /// Background color for the header circular agent avatar.
  final Color agentAvatarColor;

  /// Text color for the header agent avatar letter.
  final Color agentAvatarTextColor;

  /// Background color for the small circular avatar beside incoming messages.
  final Color agentBubbleAvatarColor;

  /// Text color for the small circular avatar letter beside incoming messages.
  final Color agentBubbleAvatarTextColor;

  /// Background color for system notifications and session pills.
  final Color systemPillColor;

  /// Text color for system notifications and session pills.
  final Color systemPillTextColor;

  /// Color used for timestamps beneath message bubbles.
  final Color timestampColor;

  /// Color used for the double checkmark read receipt icons.
  final Color readReceiptColor;

  /// Color of the online status indicator badge on the avatar.
  final Color onlineBadgeColor;

  /// Background color of the bottom message input container.
  final Color inputBackgroundColor;

  /// Text color for the input field placeholder/hint.
  final Color inputHintColor;

  /// Color for the send button icon in its inactive state.
  final Color sendButtonColor;

  /// Color for the send button icon when text is entered.
  final Color sendButtonActiveColor;

  /// Creates a [View360ChatTheme] configuration.
  const View360ChatTheme({
    this.primaryColor = const Color(0xFF4E37D3),
    this.backgroundColor = const Color(0xFFFAFAFD),
    this.headerBackgroundColor = Colors.white,
    this.userBubbleColor = const Color(0xFF4E37D3),
    this.userTextColor = Colors.white,
    this.agentBubbleColor = Colors.white,
    this.agentTextColor = const Color(0xFF1E293B),
    this.agentAvatarColor = const Color(0xFF3F4E65),
    this.agentAvatarTextColor = Colors.white,
    this.agentBubbleAvatarColor = const Color(0xFFEDE9FE),
    this.agentBubbleAvatarTextColor = const Color(0xFF4E37D3),
    this.systemPillColor = const Color(0xFFEEF2F6),
    this.systemPillTextColor = const Color(0xFF64748B),
    this.timestampColor = const Color(0xFF9CA3AF),
    this.readReceiptColor = const Color(0xFF4E37D3),
    this.onlineBadgeColor = const Color(0xFF22C55E),
    this.inputBackgroundColor = Colors.white,
    this.inputHintColor = const Color(0xFF9CA3AF),
    this.sendButtonColor = const Color(0xFF9CA3AF),
    this.sendButtonActiveColor = const Color(0xFF4E37D3),
  });
}

