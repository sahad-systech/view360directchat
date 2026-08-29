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
Future<void> getFCMToken({
  required String userId,
  required String baseUrl,
  required String appId,
}) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    await ChatService(
      baseUrl: baseUrl,
      appId: appId,
    ).notificationToken(token: token!, userId: userId);
  } catch (e) {
    debugPrint(e.toString());
  }
}
