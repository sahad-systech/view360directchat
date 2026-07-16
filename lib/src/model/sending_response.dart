class ChatSentResponse {
  String? message;
  bool status;
  String? error;
  bool? isOutOfOfficeTime;


  ChatSentResponse(
      {this.message,
      required this.status,
      this.error,
      required this.isOutOfOfficeTime});

  factory ChatSentResponse.fromJson(Map<String, dynamic> json) {
    final isOutOfOfficeTime = json["out_off_hour"];
  
    if (isOutOfOfficeTime) {
      return ChatSentResponse(
        status: true,
        message: json['content']?['message'] ?? 'Out of office time',
        isOutOfOfficeTime: true,
      );
    }
    return ChatSentResponse(
      message: json['message'],
      status: json['status'],
      isOutOfOfficeTime: false,
    );
  }

  factory ChatSentResponse.error(String error) {
    return ChatSentResponse(
        status: false, error: error, isOutOfOfficeTime: false);
  }
}
