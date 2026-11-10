import '../../model/chat_list_response.dart';

/// Represents a message or system event displayed within the View360 chat UI.
class View360ChatMessage {
  /// Unique identifier of the message.
  final String id;

  /// Text content of the message.
  final String content;

  /// Whether this message was sent by the customer/current user.
  final bool isUser;

  /// Whether this message is a centered system announcement or status pill.
  final bool isSystem;

  /// Formatted time string displayed beneath the message (e.g. "16:29").
  final String time;

  /// Whether the message has been delivered/seen (renders double checkmark for user messages).
  final bool isSeen;

  /// Optional list of file attachments or media URLs.
  final List<String> files;

  /// Creates a [View360ChatMessage].
  const View360ChatMessage({
    required this.id,
    required this.content,
    this.isUser = false,
    this.isSystem = false,
    this.time = '',
    this.isSeen = true,
    this.files = const [],
  });

  /// Convenient factory for creating an outgoing user message.
  factory View360ChatMessage.user({
    required String content,
    String? time,
    bool isSeen = true,
    String? id,
    List<String> files = const [],
  }) {
    return View360ChatMessage(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      isSystem: false,
      time: time ?? formatCurrentTime(),
      isSeen: isSeen,
      files: files,
    );
  }

  /// Convenient factory for creating an incoming agent message.
  factory View360ChatMessage.agent({
    required String content,
    String? time,
    String? id,
    List<String> files = const [],
  }) {
    return View360ChatMessage(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      isSystem: false,
      time: time ?? formatCurrentTime(),
      isSeen: true,
      files: files,
    );
  }

  /// Convenient factory for creating a centered system status banner.
  factory View360ChatMessage.system({required String content, String? id}) {
    return View360ChatMessage(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      isSystem: true,
      time: '',
      isSeen: false,
    );
  }

  /// Adapts an API [ChatMessage] model into a UI [View360ChatMessage].
  factory View360ChatMessage.fromChatMessage(ChatMessage message) {
    final sender = message.senderType.toLowerCase();
    final isCustomer = sender == 'customer';
    final isSys = sender == 'system' || sender == 'queue';

    return View360ChatMessage(
      id: message.id.toString(),
      content: message.content,
      isUser: isCustomer,
      isSystem: isSys,
      time: parseTimeString(message.createdAt),
      isSeen: true,
      files: message.files,
    );
  }

  /// Sample messages that mirror the initial preview layout shown in the View360 chat design.
  static List<View360ChatMessage> get defaultSampleMessages => [
    View360ChatMessage.system(content: 'Chat Session Created'),
    const View360ChatMessage(
      id: 'sample-1',
      content: 'Halo',
      isUser: true,
      time: '16:29',
      isSeen: true,
    ),
    const View360ChatMessage(
      id: 'sample-2',
      content:
          'You are currently in the queue. There are 1 users ahead of you. A representative will assist you as soon as possible. We appreciate your patience.',
      isUser: false,
      time: '16:29',
    ),
    const View360ChatMessage(
      id: 'sample-3',
      content: 'Halo',
      isUser: true,
      time: '10:59',
      isSeen: true,
    ),
    const View360ChatMessage(
      id: 'sample-4',
      content: 'Halo',
      isUser: true,
      time: '10:59',
      isSeen: true,
    ),
  ];

  /// Formats the current local time as "HH:mm".
  static String formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Parses an ISO 8601 timestamp string into a local "HH:mm" display string.
  static String parseTimeString(String raw) {
    if (raw.isEmpty) return formatCurrentTime();
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final hour = parsed.toLocal().hour.toString().padLeft(2, '0');
      final minute = parsed.toLocal().minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    // Return last 5 chars if in format like "HH:MM"
    if (raw.length >= 5 && raw.contains(':')) {
      return raw.substring(raw.length - 5);
    }
    return raw;
  }
}
