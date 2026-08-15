class ChateRegisterResponse {
  final bool success;
  final String? message;
  final bool isInQueue;

  const ChateRegisterResponse({
    required this.success,
    this.message,
    required this.isInQueue,
  });

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

  factory ChateRegisterResponse.error(String errorMessage) =>
      ChateRegisterResponse(
        success: false,
        message: errorMessage,
        isInQueue: false,
      );
}
