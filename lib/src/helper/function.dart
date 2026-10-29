import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';

/// Resolves the standard MIME content type string based on the given file [path] extension.
String getMimeType(String path) {
  final extension = path.split('.').last.toLowerCase();

  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'pdf':
      return 'application/pdf';
    case 'mp4':
      return 'video/mp4';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'csv':
      return 'text/csv';
    default:
      return 'application/octet-stream'; // Fallback for unknown types
  }
}

/// Fetches the Firebase Cloud Messaging device token and syncs it with View360 servers.
///
/// Handles null or empty tokens safely and skips backend registration when
/// a token is unavailable.
///
/// [tokenProvider] is an optional callback to provide the FCM token, useful for
/// testing or custom token management. If omitted, defaults to [FirebaseMessaging.instance.getToken].
/// [chatService] is an optional [ChatService] instance, primarily for testing.
/// [messaging] is an optional [FirebaseMessaging] instance for dependency injection.
Future<void> getFCMToken({
  required String userId,
  required String baseUrl,
  required String appId,
  Future<String?> Function()? tokenProvider,
  ChatService? chatService,
  FirebaseMessaging? messaging,
}) async {
  try {
    final String? token;
    if (tokenProvider != null) {
      token = await tokenProvider();
    } else if (messaging != null) {
      token = await messaging.getToken();
    } else {
      token = await FirebaseMessaging.instance.getToken();
    }

    if (token == null || token.trim().isEmpty) {
      debugPrint('FCM token is null or empty, skipping token registration');
      return;
    }

    final service = chatService ??
        ChatService(
          baseUrl: baseUrl,
          appId: appId,
        );

    await service.notificationToken(token: token.trim(), userId: userId);
  } catch (e) {
    debugPrint(e.toString());
  }
}
