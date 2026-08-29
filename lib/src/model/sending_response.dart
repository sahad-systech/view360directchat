/// Response object returned after sending a chat message.
class ChatSentResponse {
  /// Informational message from the server.
  String? message;

  /// Whether the message was successfully dispatched.
  bool status;

  /// Error details if the message failed to send.
  String? error;

  /// Creates a [ChatSentResponse] instance.
  ChatSentResponse({
    this.message,
    required this.status,
    this.error,
  });

  /// Constructs a successful [ChatSentResponse] from JSON response.
  factory ChatSentResponse.fromJson(Map<String, dynamic> json) {
    return ChatSentResponse(
      message: 'message sent successfully',
      status: true,
    );
  }

  /// Constructs an error [ChatSentResponse] with the provided [error] message.
  factory ChatSentResponse.error(String error) {
    return ChatSentResponse(
      status: false,
      error: error,
    );
  }
}

