/// Response model containing token and room information for LiveKit authentication.
class FetchTokenModel {
  /// LiveKit JWT connection token.
  final String token;

  /// Room name or identifier on LiveKit server.
  final String room;

  /// Creates a [FetchTokenModel] instance.
  FetchTokenModel({required this.token, required this.room});

  /// Constructs a [FetchTokenModel] from a JSON map.
  factory FetchTokenModel.fromJson(Map<String, dynamic> json) {
    return FetchTokenModel(
      token: json['token'] as String? ?? '',
      room: json['room'] as String? ?? '',
    );
  }
}

