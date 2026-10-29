import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:view360directchat/src/api/api_service.dart';
import 'package:view360directchat/src/local/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      View360ChatPrefs.chatIdKey: 'chat-123',
      View360ChatPrefs.customerIdKey: 'cust-456',
      View360ChatPrefs.customerNameKey: 'Test User',
      View360ChatPrefs.customerEmailKey: 'test@example.com',
      View360ChatPrefs.customerPhoneKey: '+1234567890',
      View360ChatPrefs.isInQueue: false,
    });
  });

  group('HTTPS Base URLs', () {
    test('supports standard HTTPS base URL without trailing slash', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/chat-integration/chat');

      expect(uri.scheme, 'https');
      expect(uri.host, 'chat.view360.cx');
      expect(uri.path, '/convapi/chat-integration/chat');
      expect(uri.toString(), 'https://chat.view360.cx/convapi/chat-integration/chat');
    });

    test('supports HTTPS with custom port', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx:8443',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/customer/message');

      expect(uri.scheme, 'https');
      expect(uri.host, 'chat.view360.cx');
      expect(uri.port, 8443);
      expect(uri.path, '/convapi/customer/message');
      expect(uri.toString(), 'https://chat.view360.cx:8443/convapi/customer/message');
    });

    test('normalizes uppercase HTTPS scheme to lowercase', () {
      final uri = ChatService.resolveUrl('HTTPS://chat.view360.cx', '/test');

      expect(uri.scheme, 'https');
      expect(uri.host, 'chat.view360.cx');
      expect(uri.path, '/test');
      expect(uri.toString(), 'https://chat.view360.cx/test');
    });

    test('does not silently downgrade HTTPS to HTTP', () {
      final service = ChatService(
        baseUrl: 'https://secure.view360.cx',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/customer/chat/closeChat');

      expect(uri.scheme, equals('https'));
      expect(uri.scheme, isNot(equals('http')));
      expect(uri.toString().startsWith('https://'), isTrue);
    });
  });

  group('HTTP Base URLs', () {
    test('supports standard HTTP base URL without upgrading to HTTPS', () {
      final service = ChatService(
        baseUrl: 'http://chat.view360.cx',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/chat-integration/chat');

      expect(uri.scheme, 'http');
      expect(uri.host, 'chat.view360.cx');
      expect(uri.path, '/convapi/chat-integration/chat');
      expect(uri.toString(), 'http://chat.view360.cx/convapi/chat-integration/chat');
    });

    test('supports HTTP with localhost and port without malformed authority', () {
      final service = ChatService(
        baseUrl: 'http://localhost:8080',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/customer/message');

      expect(uri.scheme, 'http');
      expect(uri.host, 'localhost');
      expect(uri.port, 8080);
      expect(uri.path, '/convapi/customer/message');
      expect(uri.toString(), 'http://localhost:8080/convapi/customer/message');
    });

    test('supports HTTP with IPv4 address and port', () {
      final service = ChatService(
        baseUrl: 'http://127.0.0.1:3000',
        appId: 'test-app',
      );
      final uri = service.buildUri('/widgetapi/messages/updateFCM');

      expect(uri.scheme, 'http');
      expect(uri.host, '127.0.0.1');
      expect(uri.port, 3000);
      expect(uri.path, '/widgetapi/messages/updateFCM');
      expect(uri.toString(), 'http://127.0.0.1:3000/widgetapi/messages/updateFCM');
    });

    test('normalizes uppercase HTTP scheme to lowercase', () {
      final uri = ChatService.resolveUrl('HTTP://localhost:8080', '/test');

      expect(uri.scheme, 'http');
      expect(uri.host, 'localhost');
      expect(uri.port, 8080);
      expect(uri.toString(), 'http://localhost:8080/test');
    });
  });

  group('Trailing Slashes Handling', () {
    test('handles single trailing slash on base URL without duplicate slashes', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/chat-integration/chat');

      expect(uri.path, '/convapi/chat-integration/chat');
      expect(uri.toString(), 'https://chat.view360.cx/convapi/chat-integration/chat');
    });

    test('handles multiple trailing slashes on base URL', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx///',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/chat-integration/chat');

      expect(uri.path, '/convapi/chat-integration/chat');
      expect(uri.toString(), 'https://chat.view360.cx/convapi/chat-integration/chat');
    });

    test('handles endpoint path without leading slash', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/',
        appId: 'test-app',
      );
      final uri = service.buildUri('convapi/chat-integration/chat');

      expect(uri.path, '/convapi/chat-integration/chat');
      expect(uri.toString(), 'https://chat.view360.cx/convapi/chat-integration/chat');
    });

    test('handles multiple leading slashes in endpoint path', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx',
        appId: 'test-app',
      );
      final uri = service.buildUri('///convapi///customer///message');

      expect(uri.path, '/convapi/customer/message');
      expect(uri.toString(), 'https://chat.view360.cx/convapi/customer/message');
    });

    test('preserves trailing slash on endpoint path when explicitly specified', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/chat-integration/chat/');

      expect(uri.path, '/convapi/chat-integration/chat/');
      expect(uri.toString(), 'https://chat.view360.cx/convapi/chat-integration/chat/');
    });
  });

  group('Base URLs Containing Paths', () {
    test('preserves single-segment base path without trailing slash', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/api',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/chat-integration/chat');

      expect(uri.path, '/api/convapi/chat-integration/chat');
      expect(uri.toString(), 'https://chat.view360.cx/api/convapi/chat-integration/chat');
    });

    test('preserves single-segment base path with trailing slash', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/api/',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/chat-integration/chat');

      expect(uri.path, '/api/convapi/chat-integration/chat');
      expect(uri.toString(), 'https://chat.view360.cx/api/convapi/chat-integration/chat');
    });

    test('preserves multi-segment base path with trailing slash', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/v1/customer-service/',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/customer/message');

      expect(uri.path, '/v1/customer-service/convapi/customer/message');
      expect(uri.toString(), 'https://chat.view360.cx/v1/customer-service/convapi/customer/message');
    });

    test('preserves multi-segment base path without trailing slash', () {
      final service = ChatService(
        baseUrl: 'http://localhost:8080/v2/tenant-app',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/customer/chat/closeChat');

      expect(uri.scheme, 'http');
      expect(uri.host, 'localhost');
      expect(uri.port, 8080);
      expect(uri.path, '/v2/tenant-app/convapi/customer/chat/closeChat');
      expect(uri.toString(), 'http://localhost:8080/v2/tenant-app/convapi/customer/chat/closeChat');
    });
  });

  group('Query Parameter Preservation and Normalization', () {
    test('preserves existing query parameters in base URL', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/api?env=staging&org=view360',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/chat-integration/chat');

      expect(uri.path, '/api/convapi/chat-integration/chat');
      expect(uri.queryParameters['env'], 'staging');
      expect(uri.queryParameters['org'], 'view360');
    });

    test('merges base URL query parameters with endpoint query parameters', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/api?env=staging',
        appId: 'test-app',
      );
      final uri = service.buildUri(
        '/convapi/customer/message/chat-100',
        {'web': 'true'},
      );

      expect(uri.path, '/api/convapi/customer/message/chat-100');
      expect(uri.queryParameters['env'], 'staging');
      expect(uri.queryParameters['web'], 'true');
    });

    test('merges query parameters defined directly in endpoint string', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx?env=production',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/customer/message/123?web=true');

      expect(uri.queryParameters['env'], 'production');
      expect(uri.queryParameters['web'], 'true');
    });

    test('endpoint query parameters override conflicting base URL query parameters', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx?version=1.0&env=staging',
        appId: 'test-app',
      );
      final uri = service.buildUri('/convapi/chat', {'version': '2.0'});

      expect(uri.queryParameters['env'], 'staging');
      expect(uri.queryParameters['version'], '2.0');
    });

    test('safely encodes query parameters with special characters', () {
      final service = ChatService(
        baseUrl: 'https://chat.view360.cx',
        appId: 'test-app',
      );
      final uri = service.buildUri(
        '/convapi/customer/message/chatQueueMessages',
        {
          'customerId': 'cust 123',
          'channelChatId': 'john+doe@example.com',
        },
      );

      expect(uri.queryParameters['customerId'], 'cust 123');
      expect(uri.queryParameters['channelChatId'], 'john+doe@example.com');
      expect(uri.toString(), contains('channelChatId=john%2Bdoe%40example.com'));
      expect(uri.toString(), contains('customerId=cust+123'));
    });
  });

  group('Invalid Base URLs', () {
    final invalidUrls = [
      '',
      '   ',
      'chat.view360.cx',
      'view360.cx/api',
      'ftp://chat.view360.cx',
      'ws://chat.view360.cx',
      'wss://chat.view360.cx',
      'file:///var/log',
      'javascript:alert(1)',
      'http://',
      'https://',
      'http:///path',
      'https:///path',
      '://invalid',
    ];

    test('ChatService.resolveUrl throws FormatException for invalid URLs', () {
      for (final invalid in invalidUrls) {
        expect(
          () => ChatService.resolveUrl(invalid, '/convapi/chat'),
          throwsA(isA<FormatException>()),
          reason: 'Expected FormatException for resolveUrl with "$invalid"',
        );
      }
    });

    test('ChatService.buildUri throws FormatException for invalid URLs', () {
      for (final invalid in invalidUrls) {
        final service = ChatService(baseUrl: invalid, appId: 'test-app');
        expect(
          () => service.buildUri('/convapi/chat'),
          throwsA(isA<FormatException>()),
          reason: 'Expected FormatException for buildUri with "$invalid"',
        );
      }
    });

    test('createChatSession throws FormatException when baseUrl is invalid', () async {
      final service = ChatService(baseUrl: 'invalid-url', appId: 'test-app');
      expect(
        () => service.createChatSession(
          chatContent: 'Hello',
          customerName: 'Alice',
          customerEmail: 'alice@example.com',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fetchMessages throws FormatException when baseUrl is invalid', () async {
      final service = ChatService(baseUrl: 'ftp://not-http.com', appId: 'test-app');
      expect(
        () => service.fetchMessages(),
        throwsA(isA<FormatException>()),
      );
    });

    test('fetchMessagesWhenChatInQueue throws FormatException when baseUrl is invalid', () async {
      final service = ChatService(baseUrl: 'http://', appId: 'test-app');
      expect(
        () => service.fetchMessagesWhenChatInQueue(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ChatService Request Verification with MockClient', () {
    test('createChatSession makes request to exact HTTP URL with base path', () async {
      Uri? requestedUri;
      String? appIdHeader;
      String? contentType;

      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        appIdHeader = request.headers['app-id'];
        contentType = request.headers['Content-Type'];
        return http.Response(
          jsonEncode({
            'customer': {'id': '101'},
            'is_queue': false,
          }),
          200,
        );
      });

      final service = ChatService(
        baseUrl: 'http://localhost:8080/prefix/',
        appId: 'my-app-id',
        client: mockClient,
      );

      final response = await service.createChatSession(
        chatContent: 'Hello',
        customerName: 'Alice',
        customerEmail: 'alice@example.com',
      );

      expect(response.success, isTrue);
      expect(requestedUri, isNotNull);
      expect(requestedUri!.scheme, 'http');
      expect(requestedUri!.host, 'localhost');
      expect(requestedUri!.port, 8080);
      expect(requestedUri!.path, '/prefix/convapi/chat-integration/chat');
      expect(appIdHeader, 'my-app-id');
      expect(contentType, 'application/json');
    });

    test('createChatSession makes request to exact HTTPS URL without double slashes', () async {
      Uri? requestedUri;

      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'customer': {'id': '202'},
            'is_queue': false,
          }),
          200,
        );
      });

      final service = ChatService(
        baseUrl: 'https://chat.view360.cx///',
        appId: 'my-app-id',
        client: mockClient,
      );

      await service.createChatSession(
        chatContent: 'Hello',
        customerName: 'Bob',
        customerEmail: 'bob@example.com',
      );

      expect(requestedUri, isNotNull);
      expect(requestedUri!.scheme, 'https');
      expect(requestedUri!.host, 'chat.view360.cx');
      expect(requestedUri!.path, '/convapi/chat-integration/chat');
      expect(requestedUri.toString(), 'https://chat.view360.cx/convapi/chat-integration/chat');
    });

    test('sendChatMessage sends multipart request to normalized HTTP URL', () async {
      Uri? requestedUri;
      String? appIdHeader;

      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        appIdHeader = request.headers['app-id'];
        return http.Response(
          jsonEncode({'success': true, 'message': 'Message sent'}),
          200,
        );
      });

      final service = ChatService(
        baseUrl: 'http://localhost:3000/api/',
        appId: 'my-app-id',
        client: mockClient,
      );

      final response = await service.sendChatMessage(chatContent: 'Test Message');

      expect(response.status, isTrue);
      expect(requestedUri, isNotNull);
      expect(requestedUri!.scheme, 'http');
      expect(requestedUri!.host, 'localhost');
      expect(requestedUri!.port, 3000);
      expect(requestedUri!.path, '/api/convapi/customer/message');
      expect(appIdHeader, 'my-app-id');
    });

    test('fetchMessages fetches from normalized URL with chatId and web=true', () async {
      Uri? requestedUri;

      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'messagesInChat': [
              {'id': 1, 'message': 'Hello'}
            ]
          }),
          200,
        );
      });

      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/subpath',
        appId: 'my-app-id',
        client: mockClient,
      );

      final response = await service.fetchMessages();

      expect(response.messages, isNotEmpty);
      expect(requestedUri, isNotNull);
      expect(requestedUri!.scheme, 'https');
      expect(requestedUri!.host, 'chat.view360.cx');
      expect(requestedUri!.path, '/subpath/convapi/customer/message/chat-123');
      expect(requestedUri!.queryParameters['web'], 'true');
    });

    test('fetchMessagesWhenChatInQueue encodes query parameters cleanly', () async {
      Uri? requestedUri;

      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode([]), 200);
      });

      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/',
        appId: 'my-app-id',
        client: mockClient,
      );

      await service.fetchMessagesWhenChatInQueue();

      expect(requestedUri, isNotNull);
      expect(requestedUri!.path, '/convapi/customer/message/chatQueueMessages');
      expect(requestedUri!.queryParameters['customerId'], 'cust-456');
      expect(requestedUri!.queryParameters['channelChatId'], 'test@example.com');
    });

    test('notificationToken sends POST request to normalized URL using client', () async {
      Uri? requestedUri;
      String? requestBody;

      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        requestBody = request.body;
        return http.Response('', 200);
      });

      final service = ChatService(
        baseUrl: 'http://localhost:8080/api/',
        appId: 'my-app-id',
        client: mockClient,
      );

      await service.notificationToken(token: 'fcm-token-123', userId: 'user-456');

      expect(requestedUri, isNotNull);
      expect(requestedUri!.scheme, 'http');
      expect(requestedUri!.path, '/api/widgetapi/messages/updateFCM');
      expect(requestBody, contains('"customerId":"user-456"'));
      expect(requestBody, contains('"fcmToken":"fcm-token-123"'));
    });

    test('closeChat sends POST request to normalized URL using client', () async {
      Uri? requestedUri;
      String? requestBody;

      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        requestBody = request.body;
        return http.Response('{"status":"closed"}', 200);
      });

      final service = ChatService(
        baseUrl: 'https://chat.view360.cx/v2/',
        appId: 'my-app-id',
        client: mockClient,
      );

      await service.closeChat();

      expect(requestedUri, isNotNull);
      expect(requestedUri!.scheme, 'https');
      expect(requestedUri!.path, '/v2/convapi/customer/chat/closeChat');
      expect(requestBody, contains('"chatId"'));
    });
  });
}
