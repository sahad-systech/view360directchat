import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:view360directchat/view360directchat.dart';

/// Callback signature triggered when a new message is received via socket.
typedef OnMessageReceived =
    void Function({
      required String content,
      List<String>? filePaths,
      required dynamic response,
      required String senderType,
      required String createdAt,
    });

/// Callback signature triggered when an agent joins the chat room.
typedef OnAgentJoin = void Function({required String name});

/// Callback signature triggered when an agent closes the chat session.
typedef OnAgentClose = void Function();

/// Callback signature triggered when an agent  the chat session due to inactivity.
typedef OnRemovedByInActivity = void Function({required String reason});

/// Callback signature triggered when an agent closes the chat session.
typedef OnChatTransfer = void Function({required String name});

/// Singleton manager for real-time WebSocket communication with View360 socket server.
class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  late io.Socket _socket;

  /// Callback executed upon receiving a message.
  OnMessageReceived? onMessageReceived;

  /// Callback executed when an agent joins the conversation.
  OnAgentJoin? onAgentJoin;

  /// Callback executed when an agent terminates the chat session.
  OnAgentClose? onAgentClose;

  /// Callback executed when an agent terminates the chat session.
  OnChatTransfer? onChatTransfer;

  /// Callback executed when an agent due to inactivity the chat session.
  OnAgentClose? onRemovedByInActivity;

  /// Returns the singleton instance of [SocketManager].
  factory SocketManager() => _instance;

  SocketManager._internal();

  /// Connects to the View360 socket server at [baseUrl] with specified callbacks.
  ///
  /// [baseUrl] is the target host domain.
  /// [onMessage] handles incoming chat messages.
  /// [onAgentJoin] handles agent join events.
  /// [onAgentClose] handles session closure events.
  /// [onChatTransfer] handles chat transfer events.
  /// [onRemovedByInActivity] handles chat removed events.
  /// [onConnected] callback triggered when the socket connection is successfully established.
  void connect({
    String? baseUrl,
    OnMessageReceived? onMessage,
    OnAgentJoin? onAgentJoin,
    OnAgentClose? onAgentClose,
    OnChatTransfer? onChatTransfer,
    OnRemovedByInActivity? onRemovedByInActivity,
    void Function()? onConnected,
  }) {
    onMessageReceived = onMessage;
    onAgentJoin = onAgentJoin;
    onAgentClose = onAgentClose;
    onChatTransfer = onChatTransfer;
    onRemovedByInActivity = onRemovedByInActivity;
    
    final effectiveBaseUrl = baseUrl ?? (View360.isInitialized ? View360.config.baseUrl : null);
    if (effectiveBaseUrl == null || effectiveBaseUrl.isEmpty) {
      throw ArgumentError('baseUrl is required or View360 must be initialized');
    }

    // ✅ Initialize the socket first
    _socket = io.io(
      effectiveBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/chatsocket.io')
          .enableAutoConnect()
          .build(),
    );

    // ✅ Now it's safe to check connection
    if (_socket.connected) {
      onConnected?.call();
      return;
    }
    _socket.connect();

    _socket.onConnect((_) async {
      final String? customerId = await View360ChatPrefs.getCustomerId();
      if (customerId != null) {
        socket.emit("customerSetup", {"id": customerId});
        socket.emit("join chat", 0);
      }
      debugPrint('view360 socket connected.');
      if (onConnected != null) {
        onConnected(); // ✅ Invoke the callback here
      }
    });

    _socket.onDisconnect((_) {
      debugPrint('Disconnected from view360 chat socket');
    });

    _socket.on('chat_assigned', (data) {
      View360ChatPrefs.changeQueueStatus(false);
      View360ChatPrefs.setChatId(data["id"].toString());
      onAgentJoin?.call(name: data['user']['name'] ?? '');
    });
    _socket.on('chat_closed', (data) {
      View360ChatPrefs.removeCustomerId();
      onAgentClose?.call();
    });
    _socket.on('chat_removed', (data) {
      View360ChatPrefs.removeCustomerId();
      onRemovedByInActivity?.call(
        reason:
            data['message'] ??
            'chat session has been closed due to inactivity.',
      );
    });
    _socket.on('chat_transfer_event', (data) {
      onChatTransfer?.call(name: data['agentName'] ?? '');
    });

    _socket.off('message received');
    _socket.on('message received', (data) {
      final messageMap = data["message"] is Map ? data["message"] : data;
      final content = (messageMap["content"] ?? "").toString();
      final List<String>? filePaths = messageMap["file_path"] == null
          ? null
          : (messageMap["file_path"] as List<dynamic>).cast<String>();
      onMessageReceived?.call(
        content: content,
        filePaths: filePaths,
        response: data,
        senderType: (messageMap["senderType"] ?? "").toString(),
        createdAt: (messageMap["createdAt"] ?? "").toString(),
      );
    });
  }

  /// The underlying [io.Socket] instance.
  io.Socket get socket => _socket;

  /// Disconnects the socket and removes all event listeners.
  void disconnect() {
    try {
      _socket.clearListeners();
      _socket.disconnect();
    } catch (_) {
      // Ignore LateInitializationError if _socket was never connected
    }
  }
}
