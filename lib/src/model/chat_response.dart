class ChateRegisterResponse {
  final bool success;
  final String? message;
  final bool isInQueue;
  final bool isOutOfOfficeTime;

  const ChateRegisterResponse({
    required this.success,
    this.message,
    required this.isInQueue,
    required this.isOutOfOfficeTime,
  });

  factory ChateRegisterResponse.fromJson(Map<String, dynamic> json) {
    final bool isOutOfOfficeTime = json['out_off_hour'] ?? false;
    final bool isInQueue = json['is_queue'] ?? false;

    if (isOutOfOfficeTime) {
      return ChateRegisterResponse(
        success: true,
        message: json['message'] ?? 'Out of office time',
        isInQueue: true,
        isOutOfOfficeTime: true,
      );
    }

    if (isInQueue) {
      return ChateRegisterResponse(
        success: true,
        message: json['message'] ?? 'Agent not available',
        isInQueue: true,
        isOutOfOfficeTime: false,
      );
    }

    return const ChateRegisterResponse(
      success: true,
      isInQueue: false,
      isOutOfOfficeTime: false,
    );
  }

  factory ChateRegisterResponse.error(String errorMessage) =>
      ChateRegisterResponse(
        success: false,
        message: errorMessage,
        isInQueue: false,
        isOutOfOfficeTime: false,
      );
}
