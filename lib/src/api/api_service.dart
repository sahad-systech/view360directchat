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

/// Service responsible for managing View360 chat HTTP API interactions,
/// session registration, message delivery, history retrieval, and session termination.
class ChatService {
  /// The base URL for the View360 API endpoints.
  final String baseUrl;

  /// The unique application identifier assigned by View360.
  final String appId;

  /// Creates an instance of [ChatService] with the specified [baseUrl] and [appId].
  ChatService({required this.baseUrl, required this.appId});

  /// Emits socket events to set up customer session and join the chat room.
  Future<void> socketEmitIsWorking(String customerId) async {
    Future.delayed(const Duration(seconds: 1), () {
      SocketManager().socket.emit("customerSetup", {"id": customerId});
      SocketManager().socket.emit("join chat", 0);
    });
  }

  /// Creates a new chat session on View360 backend for a customer.
  ///
  /// [chatContent] is the initial message sent by the customer.
  /// [customerName] is the display name of the customer.
  /// [customerEmail] is the optional email of the customer.
  /// [customerPhone] is the optional phone number of the customer.
  /// [languageInstance] is the optional language preference.
  /// [fetchFCMToken] when true will automatically request and register the FCM token.
  Future<ChateRegisterResponse> createChatSession({
    required String chatContent,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    String? languageInstance,
    bool? fetchFCMToken = false,
  }) async {
    if (customerEmail == null && customerPhone == null) {
      throw ChateRegisterResponse.error(
        'Customer email or phone is required please update your profile',
      );
    }
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
        'channel': 'MobileAPP',
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
        final bool isQueue = json['is_queue'] ?? false;
        final customerId = json['customer']['id']?.toString();
        await socketEmitIsWorking(customerId ?? '');
        await View360ChatPrefs.saveString(
          isInQueueValue: isQueue,
          customerIdKeyValue: customerId ?? '',
          customerNameKeyValue: customerName,
          customerEmailKeyValue: customerEmail,
          customerPhoneKeyValue: customerPhone,
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
        throw Exception(
          'Failed with status ${response.statusCode}: $responseString',
        );
      }
    } on SocketException {
      throw Exception('No Internet connection');
    } on TimeoutException {
      throw Exception('Request timed out');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Sends a text message with optional file attachments to the active chat session.
  ///
  /// [chatContent] contains the text content of the message.
  /// [filePath] is an optional list of absolute file paths to attach (supports .jpg, .jpeg, .png, .pdf, .gif, .mp4, .xlsx, .csv).
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
        'chat_id': localstorage.chatId!,
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

  /// Fetches the entire conversation message history for the currently active chat session.
  Future<ChatListResponse> fetchMessages() async {
    final View360ChatPrefsModel localstorage =
        await View360ChatPrefs.getString();
    final String? chatId = localstorage.chatId;
    if (chatId == null || chatId.isEmpty) {
      return fetchMessagesWhenChatInQueue();
    }
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

  /// Fetches the entire conversation message history when chat is in queue.
  Future<ChatListResponse> fetchMessagesWhenChatInQueue() async {
    final View360ChatPrefsModel localstorage =
        await View360ChatPrefs.getString();
    final String customerId = localstorage.customerId;
    final String channelChatId =
        localstorage.customerEmail ?? localstorage.customerPhone!;
    final Uri url = Uri.parse(
      '$baseUrl/convapi/customer/message/chatQueueMessages?customerId=$customerId&channelChatId=$channelChatId',
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
        return ChatListResponse.fromJson2(data);
      } else {
        return ChatListResponse.error2(
          'HTTP error - status code ${response.statusCode}',
        );
      }
    } on SocketException {
      return ChatListResponse.error2('No Internet connection');
    } on TimeoutException {
      return ChatListResponse.error2('Request timed out');
    } on HttpException {
      return ChatListResponse.error2('HTTP error occurred');
    } on FormatException {
      return ChatListResponse.error2('Invalid response format');
    } catch (e) {
      return ChatListResponse.error2('Unexpected error: ${e.toString()}');
    }
  }

  /// Registers or updates the Firebase Cloud Messaging [token] for the given [userId].
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

  /// Closes the active chat session on the server and clears local preferences.
  Future<void> closeChat() async {
    final localstorage = await View360ChatPrefs.getString();
    try {
      final String chatId = localstorage.chatId!;

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
