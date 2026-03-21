import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';

/// Connection states for the socket
enum SocketConnectionState { disconnected, connecting, connected, error }

/// Socket.IO client for real-time messaging and notifications
///
/// Uses a keyed listener registry so that multiple controllers can listen
/// to the same event without stepping on each other, and all listeners
/// are automatically re-registered after a reconnect.
class SocketService extends GetxService {
  io.Socket? _socket;
  final isConnected = false.obs;
  final connectionState = SocketConnectionState.disconnected.obs;

  // Reconnection with exponential backoff
  static const _backoffDelays = [1000, 2000, 4000, 8000, 16000, 30000];
  static const _maxReconnectAttempts = 10;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  String? _token;

  /// Keyed listener registry: eventName → { listenerId → callback }
  final Map<String, Map<String, Function(dynamic)>> _listeners = {};

  /// Initialize and connect with JWT token
  Future<SocketService> init() async {
    _token = await Get.find<ApiService>().getToken();
    if (_token == null) return this;

    _connect(_token!);
    return this;
  }

  void _connect(String token) {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    // Dispose old socket without clearing the listener registry
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    connectionState.value = SocketConnectionState.connecting;

    // Use same base URL as the API
    const baseUrl = 'https://api.almuntazer.net/losts';

    _socket = io.io(
      '$baseUrl/messages',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .disableReconnection() // We handle reconnection manually
          .build(),
    );

    _socket!.onConnect((_) {
      isConnected.value = true;
      connectionState.value = SocketConnectionState.connected;
      _reconnectAttempts = 0;
      _startHeartbeat();
      _reRegisterAllListeners();
      debugPrint('SocketService: Connected');
    });

    _socket!.onDisconnect((_) {
      isConnected.value = false;
      connectionState.value = SocketConnectionState.disconnected;
      _stopHeartbeat();
      debugPrint('SocketService: Disconnected');
      _scheduleReconnect();
    });

    _socket!.onConnectError((data) {
      connectionState.value = SocketConnectionState.error;
      debugPrint('SocketService: Connection error - $data');
      // If connection error looks auth-related, try refreshing the token
      final errorStr = data.toString().toLowerCase();
      if (errorStr.contains('unauthorized') ||
          errorStr.contains('jwt') ||
          errorStr.contains('token') ||
          errorStr.contains('403') ||
          errorStr.contains('401')) {
        debugPrint('SocketService: Auth error detected, refreshing token...');
        _refreshTokenAndReconnect();
      } else {
        _scheduleReconnect();
      }
    });

    _socket!.on('pong', (_) {
      // Server responded to heartbeat
    });

    // Debug: log all incoming events (remove in production)
    _socket!.onAny((event, data) {
      debugPrint('SocketService [event]: $event → $data');
    });
  }

  /// Re-register all stored listeners on the current socket instance.
  /// Called after every reconnect so controllers don't lose their listeners.
  void _reRegisterAllListeners() {
    for (final event in _listeners.keys) {
      // Remove stale handler from previous socket instance to prevent stacking
      _socket?.off(event);
      _socket?.on(event, (data) => _dispatchEvent(event, data));
    }
  }

  /// Fan out a socket event to all registered keyed listeners for that event.
  void _dispatchEvent(String event, dynamic data) {
    final eventListeners = _listeners[event];
    if (eventListeners == null) return;
    for (final callback in eventListeners.values) {
      try {
        callback(data);
      } catch (e) {
        debugPrint('SocketService: Error in listener for $event - $e');
      }
    }
  }

  /// Refresh the auth token and reconnect
  Future<void> _refreshTokenAndReconnect() async {
    try {
      final newToken = await Get.find<ApiService>().getToken();
      if (newToken != null && newToken != _token) {
        _token = newToken;
        debugPrint('SocketService: Token refreshed, reconnecting...');
        _reconnectAttempts = 0;
        _connect(_token!);
      } else {
        // Token didn't change — fall back to normal reconnect
        _scheduleReconnect();
      }
    } catch (e) {
      debugPrint('SocketService: Token refresh failed - $e');
      _scheduleReconnect();
    }
  }

  /// Schedule a reconnect with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _token == null) {
      debugPrint('SocketService: Max reconnect attempts reached');
      connectionState.value = SocketConnectionState.error;
      return;
    }

    _reconnectTimer?.cancel();
    final delayIndex =
        _reconnectAttempts.clamp(0, _backoffDelays.length - 1);
    final delay = _backoffDelays[delayIndex];
    _reconnectAttempts++;

    debugPrint(
        'SocketService: Reconnecting in ${delay}ms (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (_token != null) {
        _connect(_token!);
      }
    });
  }

  /// Start heartbeat ping every 30s
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected.value) {
        _socket?.emit('ping');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Register a keyed listener for an event.
  /// [event] - the socket event name (e.g. 'newMessage')
  /// [listenerId] - unique key per caller (e.g. 'chat_5', 'conversations')
  /// [callback] - the handler function
  void on(String event, String listenerId, Function(dynamic) callback) {
    _listeners.putIfAbsent(event, () => {});
    _listeners[event]![listenerId] = callback;

    // If socket is already connected, register the raw listener
    // (only once per event — idempotent because socket.io stacks handlers)
    if (_socket != null && _listeners[event]!.length == 1) {
      _socket!.on(event, (data) => _dispatchEvent(event, data));
    }
  }

  /// Remove a specific keyed listener.
  /// Only removes the socket-level listener when no more keyed listeners remain.
  void off(String event, String listenerId) {
    final eventListeners = _listeners[event];
    if (eventListeners == null) return;
    eventListeners.remove(listenerId);
    if (eventListeners.isEmpty) {
      _listeners.remove(event);
      _socket?.off(event);
    }
  }

  /// Emit an event
  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  /// Disconnect
  void disconnect({bool skipReconnect = false}) {
    if (skipReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }
    _stopHeartbeat();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    connectionState.value = SocketConnectionState.disconnected;
  }

  /// Reconnect with new token
  Future<void> reconnect() async {
    _reconnectAttempts = 0;
    disconnect(skipReconnect: true);
    await init();
  }

  @override
  void onClose() {
    _listeners.clear();
    disconnect(skipReconnect: true);
    super.onClose();
  }
}
