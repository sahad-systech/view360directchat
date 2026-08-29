/// Data model representing a speech-to-text transcript message during a voice call.
class TranscriptModel {
  /// Unique identifier of the transcript chunk.
  final String id;

  /// The transcribed spoken text.
  final String text;

  /// Whether this utterance originated from the user (`true`) or the AI agent (`false`).
  final bool isUser;

  /// Timestamp when the transcript was generated.
  final DateTime timestamp;

  /// Creates a [TranscriptModel] instance.
  TranscriptModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

