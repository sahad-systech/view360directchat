/// Localized text labels and strings used across the View360 Chat UI.
class View360ChatStrings {
  /// Header title for the support agent.
  final String agentTitle;

  /// Header subtitle indicating status.
  final String agentSubtitle;

  /// Initial letter displayed inside the avatar circle.
  final String agentInitial;

  /// Text displayed on the centered session creation banner.
  final String sessionCreatedText;

  /// Placeholder hint inside the message input box.
  final String inputHint;

  /// Accessibility tooltip for the back navigation button.
  final String backTooltip;

  /// Accessibility tooltip for the session close/exit button.
  final String closeTooltip;

  /// Accessibility tooltip for the send message button.
  final String sendTooltip;

  /// Creates a [View360ChatStrings] configuration with default or custom labels.
  const View360ChatStrings({
    this.agentTitle = 'Agent',
    this.agentSubtitle = 'Active Support',
    this.agentInitial = 'A',
    this.sessionCreatedText = 'Chat Session Created',
    this.inputHint = 'Type a message...',
    this.backTooltip = 'Back',
    this.closeTooltip = 'Close Chat',
    this.sendTooltip = 'Send message',
  });
}

