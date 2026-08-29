/// Configuration parameters required for initializing and connecting to View360 AI Voice Call.
class View360CallConfig {
  /// Endpoint URL to fetch the LiveKit authentication token.
  final String tokenUrl;

  /// Mobile SDK identifier for authentication.
  final String sdkId;

  /// API key used for accessing View360 AI call service.
  final String apiKey;

  /// WebRTC WebSocket URL for LiveKit room connection.
  final String livekitUrl;

  /// Title displayed on persistent foreground notification (Android).
  final String notificationTitle;

  /// Content text displayed on persistent foreground notification (Android).
  final String notificationText;

  /// Creates a [View360CallConfig] instance.
  const View360CallConfig({
    required this.tokenUrl,
    required this.sdkId,
    required this.apiKey,
    required this.livekitUrl,
    this.notificationTitle = 'Active Voice Call',
    this.notificationText = 'AI voice call is running in the background.',
  });
}

