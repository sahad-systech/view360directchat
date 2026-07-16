class TranscriptModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  TranscriptModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
