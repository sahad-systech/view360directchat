import 'package:flutter/material.dart';

import 'api/api_service.dart';
import 'call/config/call_strings.dart';
import 'call/config/call_theme.dart';
import 'call/ui/view360_call_page.dart';
import 'socket/socket_managet.dart';
import 'view360_config.dart';
import 'local/local_storage.dart';

/// Single entry point for configuring and accessing the View360 package.
///
/// Example usage:
/// ```dart
/// await View360.init(
///   View360Config(
///     baseUrl: 'https://chat.view360.cx',
///     appId: 'APP_ID',
///     customer: const View360Customer(name: 'John Doe'),
///   ),
/// );
/// ```
abstract final class View360 {
  static View360Config? _config;
  static ChatService? _chatService;

  /// Initializes the global View360 configuration.
  /// 
  /// This validates the config, stores it, and restores any active session data.
  /// It does not initiate network or socket connections.
  static Future<void> init(View360Config config) async {
    _config = config;
    _chatService = null;
    
    // Ensure shared_preferences are ready and possibly restore session.
    await View360ChatPrefs.getString();
  }

  /// Returns whether View360 has been initialized with a valid [View360Config].
  static bool get isInitialized => _config != null;

  /// Returns the current active [View360Config].
  /// 
  /// Throws a [StateError] if [View360.init] hasn't been called yet.
  static View360Config get config {
    if (_config == null) {
      throw StateError('Call View360.init() first.');
    }
    return _config!;
  }

  /// Provides access to the [ChatService] instance configured with the global [View360Config].
  static ChatService get chat {
    _chatService ??= ChatService(
      baseUrl: config.baseUrl,
      appId: config.appId,
    );
    return _chatService!;
  }

  /// Provides access to the singleton [SocketManager] instance.
  static SocketManager get socket {
    return SocketManager();
  }

  /// Updates the global customer configuration dynamically.
  static void updateCustomer(View360Customer customer) {
    if (!isInitialized) return;
    _config = View360Config(
      baseUrl: _config!.baseUrl,
      appId: _config!.appId,
      customer: customer,
      call: _config!.call,
      enableLogging: _config!.enableLogging,
    );
  }

  /// Pushes the [View360CallPage] onto the navigator using the configured customer and call settings.
  /// 
  /// Throws a [StateError] if call configuration is missing.
  static Future<void> openCall(
    BuildContext context, {
    View360CallTheme? theme,
    View360CallStrings? strings,
    VoidCallback? onCallStarted,
    VoidCallback? onCallEnded,
    void Function(int rating, String feedback)? onRatingSubmitted,
    void Function(String error)? onError,
  }) async {
    final callConfig = config.call;
    if (callConfig == null) {
      throw StateError('View360Config.call is null. Cannot open call.');
    }
    
    final customer = config.customer;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => View360CallPage(
          config: callConfig,
          userName: customer?.name,
          userPhone: customer?.phone,
          userEmail: customer?.email,
          theme: theme,
          strings: strings,
          onCallStarted: onCallStarted,
          onCallEnded: onCallEnded,
          onRatingSubmitted: onRatingSubmitted,
          onError: onError,
        ),
      ),
    );
  }

  /// Clears the configuration, disconnects sockets, and resets internal state.
  static Future<void> dispose() async {
    socket.disconnect();
    _chatService = null;
    _config = null;
    await View360ChatPrefs.remove();
  }
}
