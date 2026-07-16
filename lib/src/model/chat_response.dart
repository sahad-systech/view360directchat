class ChateRegisterResponse {
  final bool success;
  final String? message;
  final bool isInQueue;
  final bool isOutOfOfficeTime;

  ChateRegisterResponse({
    required this.success,
    this.message,
    required this.isInQueue,
    required this.isOutOfOfficeTime,
  });

  factory ChateRegisterResponse.fromJson(Map<String, dynamic> json) {
    final topLevelStatus = json['status'] == true || json['status'] == 'true';
    final contentStatus = json['content']?['status'];
    final isOutOfOfficeTime = json["out_off_hour"];
    if (isOutOfOfficeTime) {
      return ChateRegisterResponse(
        success: true,
        message: json['content']?['message'] ?? 'Out of office time',
        isInQueue: true,
        isOutOfOfficeTime: true,
      );
    }
    if (!topLevelStatus || contentStatus == false || contentStatus == 'false') {
      return ChateRegisterResponse(
        success: true,
        message: json['content']?['message'] ?? 'Agent not available',
        isInQueue: true,
        isOutOfOfficeTime: false,
      );
    }

    return ChateRegisterResponse(
      success: true,
      isInQueue: false,
      isOutOfOfficeTime: false,
    );
  }

  factory ChateRegisterResponse.error(String errorMessage) {
    return ChateRegisterResponse(
      success: false,
      message: errorMessage,
      isInQueue: false,
      isOutOfOfficeTime: false,
    );
  }
}
