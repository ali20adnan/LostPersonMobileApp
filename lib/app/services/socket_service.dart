import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';

/// Socket.IO client for real-time messaging and notifications
class SocketService extends GetxService {
  io.Socket? _socket;
  final isConnected = false.obs;

  /// Initialize and connect with JWT token
  Future<SocketService> init() async {
    final token = await Get.find<ApiService>().getToken();
    if (token == null) return this;

    _connect(token);
    return this;
  }

  void _connect(String token) {
    // Base URL without /api path for socket namespace
    const baseUrl = 'https://api.almuntazer.net';

    _socket = io.io(
      '$baseUrl/messages',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(10)
          .build(),
    );

    _socket!.onConnect((_) {
      isConnected.value = true;
      debugPrint('SocketService: Connected');
    });

    _socket!.onDisconnect((_) {
      isConnected.value = false;
      debugPrint('SocketService: Disconnected');
    });

    _socket!.onConnectError((data) {
      debugPrint('SocketService: Connection error - $data');
    });
  }

  /// Listen to an event
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Remove listener
  void off(String event) {
    _socket?.off(event);
  }

  /// Emit an event
  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  /// Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
  }

  /// Reconnect with new token
  Future<void> reconnect() async {
    disconnect();
    await init();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
