import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:view360directchat/view360directchat.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'CUSTOMER_ID_KEY': 'cust_123',
      'CUSTOMER_EMAIL_KEY': 'test@example.com',
      'CUSTOMER_PHONE_KEY': '+1234567890',
    });
  });

  group('ChatListResponse.fromJson2', () {
    test('parses a valid list of message objects for queue history', () {
      final jsonList = [
        {
          'id': 101,
          'content': 'First queue message',
          'senderType': 'customer',
          'file_path': ['https://view360.cx/img.png'],
          'createdAt': '2026-10-27T10:00:00Z',
        },
        {
          'id': 102,
          'content': 'Second queue message',
          'senderType': 'agent',
          'file_path': null,
          'createdAt': '2026-10-27T10:01:00Z',
        },
      ];

      final response = ChatListResponse.fromJson2(jsonList);

      expect(response.success, isTrue);
      expect(response.isInQueue, isTrue);
      expect(response.error, isNull);
      expect(response.messages.length, 2);
      expect(response.messages[0].id, 101);
      expect(response.messages[0].content, 'First queue message');
      expect(response.messages[0].files, ['https://view360.cx/img.png']);
      expect(response.messages[1].id, 102);
      expect(response.messages[1].content, 'Second queue message');
      expect(response.messages[1].files, isEmpty);
    });

    test('handles empty list correctly', () {
      final response = ChatListResponse.fromJson2([]);

      expect(response.success, isTrue);
      expect(response.isInQueue, isTrue);
      expect(response.messages, isEmpty);
      expect(response.error, isNull);
    });

    test('filters non-map items defensively', () {
      final jsonList = [
        {
          'id': 103,
          'content': 'Valid message',
          'senderType': 'customer',
          'file_path': [],
          'createdAt': '2026-10-27T10:02:00Z',
        },
        null,
        123,
        'unexpected string',
      ];

      final response = ChatListResponse.fromJson2(jsonList);

      expect(response.success, isTrue);
      expect(response.isInQueue, isTrue);
      expect(response.messages.length, 1);
      expect(response.messages.first.id, 103);
    });
  });

  group('ChatService.fetchMessagesWhenChatInQueue', () {
    test(
      'successfully parses JSON list response from queue endpoint',
      () async {
        final mockClient = MockClient((request) async {
          expect(
            request.url.path,
            '/convapi/customer/message/chatQueueMessages',
          );
          expect(request.url.queryParameters['customerId'], 'cust_123');
          expect(
            request.url.queryParameters['channelChatId'],
            'test@example.com',
          );

          return http.Response(
            jsonEncode([
              {
                'id': 201,
                'content': 'Waiting in queue',
                'senderType': 'customer',
                'file_path': [],
                'createdAt': '2026-10-27T11:00:00Z',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = ChatService(
          baseUrl: 'https://chat.view360.cx',
          appId: 'test_app_id',
          client: mockClient,
        );

        final result = await service.fetchMessagesWhenChatInQueue();

        expect(result.success, isTrue);
        expect(result.isInQueue, isTrue);
        expect(result.error, isNull);
        expect(result.messages.length, 1);
        expect(result.messages.first.id, 201);
        expect(result.messages.first.content, 'Waiting in queue');
      },
    );

    test(
      'handles alternative map response structure with messagesInChat',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'messagesInChat': [
                {
                  'id': 202,
                  'content': 'Wrapped message',
                  'senderType': 'agent',
                  'file_path': null,
                  'createdAt': '2026-10-27T11:05:00Z',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = ChatService(
          baseUrl: 'https://chat.view360.cx',
          appId: 'test_app_id',
          client: mockClient,
        );

        final result = await service.fetchMessagesWhenChatInQueue();

        expect(result.success, isTrue);
        expect(result.isInQueue, isTrue);
        expect(result.messages.length, 1);
        expect(result.messages.first.id, 202);
        expect(result.messages.first.content, 'Wrapped message');
      },
    );

    test('handles alternative map response structure with messages', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'messages': [
              {
                'id': 203,
                'content': 'Alternative wrapped message',
                'senderType': 'agent',
                'file_path': null,
                'createdAt': '2026-10-27T11:10:00Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ChatService(
        baseUrl: 'https://chat.view360.cx',
        appId: 'test_app_id',
        client: mockClient,
      );

      final result = await service.fetchMessagesWhenChatInQueue();

      expect(result.success, isTrue);
      expect(result.isInQueue, isTrue);
      expect(result.messages.length, 1);
      expect(result.messages.first.id, 203);
    });

    test('returns clear error for unsupported response structure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'unsupportedKey': 'unexpected data'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ChatService(
        baseUrl: 'https://chat.view360.cx',
        appId: 'test_app_id',
        client: mockClient,
      );

      final result = await service.fetchMessagesWhenChatInQueue();

      expect(result.success, isFalse);
      expect(result.isInQueue, isTrue);
      expect(result.messages, isEmpty);
      expect(
        result.error,
        'Invalid response format: expected a JSON list of queue messages',
      );
    });

    test('returns error2 on non-200 HTTP status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ChatService(
        baseUrl: 'https://chat.view360.cx',
        appId: 'test_app_id',
        client: mockClient,
      );

      final result = await service.fetchMessagesWhenChatInQueue();

      expect(result.success, isFalse);
      expect(result.isInQueue, isTrue);
      expect(result.error, 'HTTP error - status code 500');
    });

    test('handles invalid JSON body (FormatException) gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('not valid json <html/>', 200);
      });

      final service = ChatService(
        baseUrl: 'https://chat.view360.cx',
        appId: 'test_app_id',
        client: mockClient,
      );

      final result = await service.fetchMessagesWhenChatInQueue();

      expect(result.success, isFalse);
      expect(result.isInQueue, isTrue);
      expect(result.error, 'Invalid response format');
    });

    test('handles SocketException gracefully', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Network unreachable');
      });

      final service = ChatService(
        baseUrl: 'https://chat.view360.cx',
        appId: 'test_app_id',
        client: mockClient,
      );

      final result = await service.fetchMessagesWhenChatInQueue();

      expect(result.success, isFalse);
      expect(result.isInQueue, isTrue);
      expect(result.error, 'No Internet connection');
    });
  });
}
