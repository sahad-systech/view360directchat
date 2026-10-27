import 'package:flutter_test/flutter_test.dart';
import 'package:view360directchat/view360directchat.dart';

void main() {
  group('ChatMessage.fromJson attachment parsing', () {
    test('handles missing file_path', () {
      final json = {
        'id': 1,
        'content': 'Hello world',
        'senderType': 'customer',
        'createdAt': '2026-10-27T10:00:00Z',
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 1);
      expect(message.content, 'Hello world');
      expect(message.senderType, 'customer');
      expect(message.createdAt, '2026-10-27T10:00:00Z');
      expect(message.files, isEmpty);
    });

    test('handles file_path: null', () {
      final json = {
        'id': 2,
        'content': 'Text only message',
        'senderType': 'agent',
        'file_path': null,
        'createdAt': '2026-10-27T10:05:00Z',
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 2);
      expect(message.content, 'Text only message');
      expect(message.files, isEmpty);
    });

    test('handles empty attachment list', () {
      final json = {
        'id': 3,
        'content': 'Message with empty list',
        'senderType': 'customer',
        'file_path': <dynamic>[],
        'createdAt': '2026-10-27T10:10:00Z',
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 3);
      expect(message.files, isEmpty);
    });

    test('preserves valid list of attachment paths', () {
      final json = {
        'id': 4,
        'content': 'Check these files',
        'senderType': 'agent',
        'file_path': [
          'https://view360.cx/files/report.pdf',
          'https://view360.cx/files/photo.png',
        ],
        'createdAt': '2026-10-27T10:15:00Z',
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 4);
      expect(message.files, [
        'https://view360.cx/files/report.pdf',
        'https://view360.cx/files/photo.png',
      ]);
    });

    test('handles unexpected attachment value types defensively', () {
      // 1. Primitive non-list values (string, integer, boolean)
      final stringFilePath = ChatMessage.fromJson({
        'id': 5,
        'content': 'String attachment',
        'file_path': 'not_a_valid_list',
      });
      expect(stringFilePath.files, isEmpty);

      final intFilePath = ChatMessage.fromJson({
        'id': 6,
        'content': 'Numeric attachment',
        'file_path': 12345,
      });
      expect(intFilePath.files, isEmpty);

      final boolFilePath = ChatMessage.fromJson({
        'id': 7,
        'content': 'Boolean attachment',
        'file_path': true,
      });
      expect(boolFilePath.files, isEmpty);

      // 2. Map instead of list
      final mapFilePath = ChatMessage.fromJson({
        'id': 8,
        'content': 'Map attachment',
        'file_path': {'url': 'https://view360.cx/file.pdf'},
      });
      expect(mapFilePath.files, isEmpty);

      // 3. List with unexpected mixed/non-string element types
      final mixedListFilePath = ChatMessage.fromJson({
        'id': 9,
        'content': 'Mixed list attachment',
        'file_path': [
          'https://view360.cx/valid.jpg',
          123,
          null,
          true,
          {'nested': 'object'},
          'https://view360.cx/valid2.png',
        ],
      });
      expect(mixedListFilePath.files, [
        'https://view360.cx/valid.jpg',
        'https://view360.cx/valid2.png',
      ]);
    });
  });
}
