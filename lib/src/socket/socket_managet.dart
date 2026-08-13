import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:view360directchat/view360directchat.dart';

typedef OnMessageReceived =
    void Function({
      required String content,
      List<String>? filePaths,
      required dynamic response,
      required String senderType,
      required String createdAt,
    });

typedef OnAgentJoin = void Function({required String name});

typedef OnAgentClose = void Function();

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  late io.Socket _socket;
  OnMessageReceived? onMessageReceived;
  OnAgentJoin? onAgentJoin;
  OnAgentClose? onAgentClose;

  factory SocketManager() => _instance;

  SocketManager._internal();

  void connect({
    required String baseUrl,
    OnMessageReceived? onMessage,
    OnAgentJoin? onAgentJoin,
    OnAgentClose? onAgentClose,
    void Function()? onConnected,
  }) {
    onMessageReceived = onMessage;
    onAgentJoin = onAgentJoin;
    onAgentClose = onAgentClose;
    // ✅ Initialize the socket first
    _socket = io.io(
      baseUrl,
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

  io.Socket get socket => _socket;

  void disconnect() {
    _socket.clearListeners();
    _socket.disconnect();
  }
}
