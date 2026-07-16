class View360CallConfig {
  final String tokenUrl;
  final String sdkId;
  final String apiKey;
  final String livekitUrl;
  final String notificationTitle;
  final String notificationText;

  const View360CallConfig({
    required this.tokenUrl,
    required this.sdkId,
    required this.apiKey,
    required this.livekitUrl,
    this.notificationTitle = 'Active Voice Call',
    this.notificationText = 'AI voice call is running in the background.',
  });
}
