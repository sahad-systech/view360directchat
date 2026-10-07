import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:view360directchat/view360directchat.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await View360.dispose();
  });

  test('View360.config throws StateError if not initialized', () {
    expect(() => View360.config, throwsStateError);
  });

  test('View360Config rejects empty appId and invalid baseUrl', () {
    expect(
      () => View360Config(baseUrl: 'https://example.com', appId: ''),
      throwsArgumentError,
    );

    expect(
      () => View360Config(baseUrl: 'example.com', appId: 'app_id'),
      throwsArgumentError,
    );
  });

  test('View360Config normalizes trailing slash', () {
    final config = View360Config(
      baseUrl: 'https://example.com/',
      appId: 'app_id',
    );
    expect(config.baseUrl, 'https://example.com');
  });

  test('View360.init initializes configuration correctly', () async {
    await View360.init(View360Config(
      baseUrl: 'https://example.com',
      appId: 'app_id',
    ));
    expect(View360.isInitialized, isTrue);
    expect(View360.config.baseUrl, 'https://example.com');
  });

  test('View360.updateCustomer updates customer correctly', () async {
    await View360.init(View360Config(
      baseUrl: 'https://example.com',
      appId: 'app_id',
    ));
    
    expect(View360.config.customer, isNull);
    
    View360.updateCustomer(const View360Customer(name: 'Jane Doe'));
    expect(View360.config.customer?.name, 'Jane Doe');
  });

  test('ChatService initializes from View360.config', () async {
    await View360.init(View360Config(
      baseUrl: 'https://example.com',
      appId: 'app_id',
    ));
    
    final chatService = View360.chat;
    expect(chatService.baseUrl, 'https://example.com');
    expect(chatService.appId, 'app_id');
  });

  test('Old style usage works without initialization', () {
    final chatService = ChatService(
      baseUrl: 'https://old.example.com',
      appId: 'old_app_id',
    );
    expect(chatService.baseUrl, 'https://old.example.com');
    expect(chatService.appId, 'old_app_id');
    
    // Attempting to construct without explicit url when not initialized throws
    expect(
      () => SocketManager().connect(baseUrl: ''),
      throwsArgumentError,
    );
  });
}
