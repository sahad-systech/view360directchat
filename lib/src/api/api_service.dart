import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../helper/function.dart';
import '../local/local_storage.dart';
import '../model/chat_list_response.dart';
import '../model/chat_response.dart';
import '../model/sending_response.dart';
import '../model/storage_pre_model.dart';
import '../socket/socket_managet.dart';

class ChatService {
  final String baseUrl;
  final String appId;

  ChatService({required this.baseUrl, required this.appId});

  Future<void> socketEmitIsWorking(String customerId) async {
    Future.delayed(const Duration(seconds: 1), () {
      SocketManager().socket.emit("customerSetup", {"id": customerId});
      SocketManager().socket.emit("join chat", 0);
    });
  }

  Future<ChateRegisterResponse> createChatSession({
    required String chatContent,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    String? languageInstance,
    bool? fetchFCMToken = false,
  }) async {
    final String updatedBaseUrl = baseUrl.replaceAll('https://', '');
    try {
      final uri = Uri.https(updatedBaseUrl, "/convapi/chat-integration/chat");

      final request = http.Request('POST', uri)
        ..headers['app-id'] = appId
        ..headers['Origin'] = 'https://view360.cx'
        ..headers['Referer'] = 'https://view360.cx/'
        ..headers['Content-Type'] = 'application/json';

      final body = {
        'ChatId': customerEmail ?? customerPhone!,
        'appId': appId,
        'channel': 'web',
        'clientId': '',
        if (customerEmail != null && customerEmail.isNotEmpty)
          'email': customerEmail,
        if (customerPhone != null && customerPhone.isNotEmpty)
          'mobile': customerPhone,
        'name': customerName,
        'messages': [
          {
            'text': {'content': chatContent, 'content_id': 'customer'},
          },
        ],
      };

      request.body = jsonEncode(body);
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 304) {
        final json = jsonDecode(responseString);
        final bool isQuieue = json['is_queue'] ?? false;
        final customerId = json['customer']['id']?.toString();
        await socketEmitIsWorking(customerId ?? '');
        await View360ChatPrefs.saveString(
          isInQueueValue: isQuieue,
          customerIdKeyValue: customerId ?? '',
          customerNameKeyValue: customerName,
          customerEmailKeyValue: customerEmail ?? '',
          customerPhoneKeyValue: customerPhone ?? '',
        );
        if (fetchFCMToken ?? false) {
          getFCMToken(
            userId: customerId.toString(),
            baseUrl: baseUrl,
            appId: appId,
          );
        }

        return ChateRegisterResponse.fromJson(json);
      } else {
        return ChateRegisterResponse.error(
          'Failed with status ${response.statusCode}: $responseString',
        );
      }
    } on SocketException {
      return ChateRegisterResponse.error('No Internet connection');
    } on TimeoutException {
      return ChateRegisterResponse.error('Request timed out');
    } on HttpException {
      return ChateRegisterResponse.error('HTTP error occurred');
    } on FormatException {
      return ChateRegisterResponse.error('Invalid response format');
    } catch (e) {
      return ChateRegisterResponse.error(e.toString());
    }
  }

  Future<ChatSentResponse> sendChatMessage({
    List<String>? filePath,
    required String chatContent,
  }) async {
    final String updatedBaseUrl = baseUrl.replaceAll('https://', '');
    const allowedExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.pdf',
      '.gif',
      '.mp4',
      '.xlsx',
      '.csv',
    ];

    try {
      final uri = Uri.https(updatedBaseUrl, "/convapi/customer/message");
      final View360ChatPrefsModel localstorage =
          await View360ChatPrefs.getString();
      final request = http.MultipartRequest('POST', uri)
        ..headers['app-id'] = appId
        ..headers['Origin'] = 'https://view360.cx'
        ..headers['Referer'] = 'https://view360.cx/';
      request.fields.addAll({
        'chat_id': localstorage.chatId,
        'content': chatContent,
        'customerId': localstorage.customerId,
      });

      if (filePath != null && filePath.isNotEmpty) {
        for (var file in filePath) {
          String ext = '.${file.split('.').last.toLowerCase()}';
          if (!allowedExtensions.contains(ext)) {
            return ChatSentResponse.error('Unsupported file extension: $ext');
          }
          String fileName = file.split('/').last;
          final mimeType = getMimeType(file);
          final parts = mimeType.split('/');
          final contentType = MediaType(parts[0], parts[1]);
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              file,
              filename: fileName,
              contentType: contentType,
            ),
          );
        }
      }
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 304) {
        final json = jsonDecode(responseString);
        return ChatSentResponse.fromJson(json);
      } else {
        return ChatSentResponse.error(
          'Failed with status ${response.statusCode}: $responseString',
        );
      }
    } on SocketException {
      return ChatSentResponse.error('No Internet connection');
    } on TimeoutException {
      return ChatSentResponse.error('Request timed out');
    } on HttpException {
      return ChatSentResponse.error('HTTP error occurred');
    } on FormatException {
      return ChatSentResponse.error('Invalid response format');
    } catch (e) {
      return ChatSentResponse.error(e.toString());
    }
  }

  Future<ChatListResponse> fetchMessages() async {
    final View360ChatPrefsModel localstorage =
        await View360ChatPrefs.getString();
    final String chatId = localstorage.chatId;
    final Uri url = Uri.parse(
      '$baseUrl/convapi/customer/message/$chatId?web=true',
    );
    final headers = {
      'app-id': appId,
      'Origin': 'https://view360.cx',
      'Referer': 'https://view360.cx/',
    };

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 20)); // Optional: set timeout
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatListResponse.fromJson(data);
      } else {
        return ChatListResponse.error(
          'HTTP error - status code ${response.statusCode}',
        );
      }
    } on SocketException {
      return ChatListResponse.error('No Internet connection');
    } on TimeoutException {
      return ChatListResponse.error('Request timed out');
    } on HttpException {
      return ChatListResponse.error('HTTP error occurred');
    } on FormatException {
      return ChatListResponse.error('Invalid response format');
    } catch (e) {
      return ChatListResponse.error('Unexpected error: ${e.toString()}');
    }
  }

  Future<void> notificationToken({
    required String token,
    required String userId,
  }) async {
    try {
      var headers = {
        'app-id': appId,
        'Origin': 'https://view360.cx',
        'Referer': 'https://view360.cx/',
      };
      var request = http.Request(
        'POST',
        Uri.parse('$baseUrl/widgetapi/messages/updateFCM'),
      );
      request.body = jsonEncode({"customerId": userId, "fcmToken": token});
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        debugPrint("FCM token updated successfully");
      } else {
        debugPrint('Failed to update FCM token');
      }
    } catch (e) {
      debugPrint('Failed to updating FCM token ${e.toString()}');
    }
  }

  Future<void> closeChat() async {
    final localstorage = await View360ChatPrefs.getString();
    final String chatId = localstorage.chatId;
    try {
      var headers = {
        'app-id': appId,
        'origin': 'https://view360.cx',
        'referer': 'https://view360.cx/',
        'Content-Type': 'application/json',
      };
      var request = http.Request(
        'POST',
        Uri.parse('$baseUrl/convapi/customer/chat/closeChat'),
      );
      final dynamic parsedChatId = int.tryParse(chatId) ?? chatId;
      request.body = jsonEncode({"chatId": parsedChatId});
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final responseString = await response.stream.bytesToString();
        debugPrint("close response $responseString");
        await View360ChatPrefs.remove();
        debugPrint("Chat closed successfully");
      } else {
        final responseString = await response.stream.bytesToString();
        debugPrint(
          "Failed to close chat: ${response.statusCode} - $responseString",
        );
      }
    } catch (e) {
      debugPrint('Failed to close chat ${e.toString()}');
    }
  }
}
