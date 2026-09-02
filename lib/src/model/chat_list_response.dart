/// Response object returned when fetching the chat message history.
class ChatListResponse {
  /// Indicates whether the fetch request succeeded.
  final bool success;

  /// The list of messages retrieved for this chat session.
  final List<ChatMessage> messages;

  /// Error description if the request failed.
  final String? error;

  /// Indicates whether the customer is in a queue.
  final bool isInQueue;

  /// Creates an instance of [ChatListResponse].
  ChatListResponse({
    required this.success,
    required this.messages,
    required this.isInQueue,
    this.error,
  });

  /// Constructs a [ChatListResponse] from decoded JSON server response.
  factory ChatListResponse.fromJson(Map<String, dynamic> json) {
    return ChatListResponse(
      success: true,
      isInQueue: false,
      messages: (json['messagesInChat'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e))
          .toList(),
    );
  }

  factory ChatListResponse.fromJson2(List<dynamic> jsonList) {
    return ChatListResponse(
      success: true,
      isInQueue: true,
      messages: jsonList.map((e) => ChatMessage.fromJson(e)).toList(),
    );
  }

  /// Constructs an error [ChatListResponse] with the provided [errorMessage].
  factory ChatListResponse.error(String errorMessage) {
    return ChatListResponse(
      success: false,
      isInQueue: false,
      messages: [],
      error: errorMessage,
    );
  }
  factory ChatListResponse.error2(String errorMessage) {
    return ChatListResponse(
      success: false,
      isInQueue: true,
      messages: [],
      error: errorMessage,
    );
  }
}

/// Represents an individual chat message in a conversation.
class ChatMessage {
  /// The unique numeric identifier of the message.
  final int id;

  /// The text content of the message.
  final String content;

  /// The sender identifier or role (e.g., 'customer', 'agent').
  final String senderType;

  /// A list of attachment file paths or URLs associated with the message.
  final List<String> files;

  /// The creation timestamp string of the message.
  final String createdAt;

  /// Creates a new [ChatMessage] instance.
  ChatMessage({
    required this.id,
    required this.content,
    required this.senderType,
    required this.files,
    required this.createdAt,
  });

  /// Constructs a [ChatMessage] from decoded JSON data.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'] ?? '',
      senderType: json['senderType'] ?? '',
      files: (json['file_path'] as List<dynamic>).cast<String>(),
      createdAt: json['createdAt'] ?? '',
      id: json['id'] ?? 0,
    );
  }
}
