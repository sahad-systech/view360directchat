class FetchTokenModel {
  final String token;
  final String room;

  FetchTokenModel({required this.token, required this.room});

  factory FetchTokenModel.fromJson(Map<String, dynamic> json) {
    return FetchTokenModel(
      token: json['token'] as String? ?? '',
      room: json['room'] as String? ?? '',
    );
  }
}
