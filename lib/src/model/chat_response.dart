/// Response model returned upon registering or creating a new chat session.
class ChateRegisterResponse {
  /// Indicates whether the session registration was successful.
  final bool success;

  /// Optional message from the server regarding the registration status.
  final String? message;

  /// Indicates whether the customer was placed in a waiting queue for an agent.
  final bool isInQueue;

  /// Creates a [ChateRegisterResponse] instance.
  const ChateRegisterResponse({
    required this.success,
    this.message,
    required this.isInQueue,
  });

  /// Constructs a [ChateRegisterResponse] from decoded JSON data.
  factory ChateRegisterResponse.fromJson(Map<String, dynamic> json) {
    final bool isInQueue = json['is_queue'] ?? false;
    if (isInQueue) {
      return ChateRegisterResponse(
        success: true,
        message: json['message'] ?? 'Agent not available',
        isInQueue: true,
      );
    }

    return const ChateRegisterResponse(
      success: true,
      isInQueue: false,
    );
  }

  /// Constructs an error [ChateRegisterResponse] with the specified [errorMessage].
  factory ChateRegisterResponse.error(String errorMessage) =>
      ChateRegisterResponse(
        success: false,
        message: errorMessage,
        isInQueue: false,
      );
}

