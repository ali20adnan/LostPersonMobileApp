import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_constants.dart';
import '../../data/models/soniox_response_model.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class SonioxService {
  WebSocketChannel? _channel;
  StreamController<SonioxResponse>? _responseController;
  StreamController<ConnectionStatus>? _statusController;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _isManualDisconnect = false;

  // Track current language configuration
  String? _currentLanguageA;
  String? _currentLanguageB;

  // Getters
  ConnectionStatus get status => _status;
  Stream<SonioxResponse>? get responseStream => _responseController?.stream;
  Stream<ConnectionStatus>? get statusStream => _statusController?.stream;

  /// Initialize the service
  void init() {
    _responseController = StreamController<SonioxResponse>.broadcast();
    _statusController = StreamController<ConnectionStatus>.broadcast();
    // Broadcast initial status
    _statusController?.add(_status);
  }

  /// Connect to Soniox WebSocket with translation configuration
  Future<bool> connect({
    required String languageA,
    required String languageB,
  }) async {
    debugPrint('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
    debugPrint('┃ SonioxService: CONNECT TO WEBSOCKET                ┃');
    debugPrint('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
    debugPrint('  Language A: $languageA');
    debugPrint('  Language B: $languageB');

    // Check if already connected with different languages
    if (_status == ConnectionStatus.connected) {
      if (_currentLanguageA == languageA && _currentLanguageB == languageB) {
        debugPrint('SonioxService: ⚠️ Already connected with same languages, returning true');
        return true;
      } else {
        debugPrint('SonioxService: ⚠️ Language change detected!');
        debugPrint('  Previous: $_currentLanguageA ↔ $_currentLanguageB');
        debugPrint('  New: $languageA ↔ $languageB');
        debugPrint('SonioxService: Disconnecting to change languages...');
        await disconnect();
        debugPrint('SonioxService: ✓ Disconnected, will reconnect with new languages');
      }
    }

    try {
      _isManualDisconnect = false;
      _updateStatus(ConnectionStatus.connecting);
      debugPrint('SonioxService: Status → connecting');

      // Create WebSocket connection
      final uri = Uri.parse(ApiConstants.sonioxWebSocketUrl);
      debugPrint('SonioxService: Connecting to: ${uri.toString()}');
      _channel = WebSocketChannel.connect(uri);
      debugPrint('SonioxService: ✓ WebSocket channel created');

      // Wait for connection to establish
      debugPrint('SonioxService: Waiting for WebSocket to be ready...');
      await _channel!.ready;
      debugPrint('SonioxService: ✓ WebSocket is ready');

      // Send initial configuration message
      debugPrint('SonioxService: Preparing configuration message...');
      final apiKey = ApiConstants.sonioxApiKey;
      debugPrint('SonioxService: API Key: ${apiKey.isEmpty ? "EMPTY/NOT SET" : "${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 4)}"}');

      final config = {
        'api_key': apiKey,
        'model': ApiConstants.sonioxModel,
        'audio_format': ApiConstants.audioFormat,
        'num_channels': ApiConstants.numChannels,
        'sample_rate': ApiConstants.sampleRate,
        'translation': {
          'type': ApiConstants.translationMode,
          'language_a': languageA,
          'language_b': languageB,
        },
      };

      debugPrint('SonioxService: Configuration:');
      debugPrint('  Model: ${config['model']}');
      debugPrint('  Audio Format: ${config['audio_format']}');
      debugPrint('  Channels: ${config['num_channels']}');
      debugPrint('  Sample Rate: ${config['sample_rate']}Hz');
      debugPrint('  Translation Mode: ${ApiConstants.translationMode}');

      final configJson = jsonEncode(config);
      debugPrint('SonioxService: Sending configuration (${configJson.length} bytes)...');
      _channel!.sink.add(configJson);
      debugPrint('SonioxService: ✓ Configuration sent - $languageA ↔ $languageB');

      // Listen to responses
      debugPrint('SonioxService: Setting up message listener...');
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );
      debugPrint('SonioxService: ✓ Message listener configured');

      _updateStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;

      // Store current language configuration
      _currentLanguageA = languageA;
      _currentLanguageB = languageB;

      debugPrint('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
      debugPrint('┃ SonioxService: ✓✓✓ CONNECTED SUCCESSFULLY ✓✓✓     ┃');
      debugPrint('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
      return true;
    } catch (e, stackTrace) {
      debugPrint('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
      debugPrint('┃ SonioxService: ✗✗✗ CONNECTION ERROR ✗✗✗            ┃');
      debugPrint('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      _updateStatus(ConnectionStatus.error);
      _scheduleReconnect(languageA, languageB);
      return false;
    }
  }

  // Track audio sending
  int _audioChunks = 0;
  int _totalAudioBytes = 0;

  /// Send audio data to Soniox
  void sendAudio(Uint8List audioData) {
    if (_status != ConnectionStatus.connected || _channel == null) {
      if (_audioChunks == 0) {
        // Only log the first time to avoid spam
        debugPrint('SonioxService: ⚠️ Cannot send audio - not connected (status: $_status)');
      }
      return;
    }

    try {
      _audioChunks++;
      _totalAudioBytes += audioData.length;

      // Log every 100th chunk (roughly every 4-6 seconds)
      if (_audioChunks % 100 == 0) {
        debugPrint('SonioxService: 📤 Sent audio chunk #$_audioChunks (${audioData.length} bytes, total: $_totalAudioBytes bytes)');
      }

      _channel!.sink.add(audioData);
    } catch (e) {
      debugPrint('SonioxService: ✗ Error sending audio chunk #$_audioChunks - $e');
      _updateStatus(ConnectionStatus.error);
    }
  }

  // Track messages received
  int _messagesReceived = 0;

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      _messagesReceived++;

      if (message is String) {
        debugPrint('SonioxService: 📥 Message #$_messagesReceived received (${message.length} chars)');
        debugPrint('SonioxService: Raw message: $message');

        final jsonData = jsonDecode(message) as Map<String, dynamic>;
        final response = SonioxResponse.fromJson(jsonData);

        debugPrint('SonioxService: Parsed response - ${response.tokens.length} tokens, finished: ${response.finished}');

        _responseController?.add(response);

        // Log for debugging
        if (response.tokens.isNotEmpty) {
          debugPrint('SonioxService: ━━━ TOKENS RECEIVED ━━━');
          for (var token in response.tokens) {
            debugPrint('  Token: "${token.text}"');
            debugPrint('    Language: ${token.language}');
            debugPrint('    Translation Status: ${token.translationStatus}');
            debugPrint('    Is Final: ${token.isFinal}');
            debugPrint('    Is Original: ${token.isOriginal}');
            debugPrint('    Is Translation: ${token.isTranslation}');
          }
          debugPrint('SonioxService: ━━━━━━━━━━━━━━━━━━━━━');
        }

        // Check if session finished
        if (response.finished == true) {
          debugPrint('SonioxService: ⚠️ Session finished by server');
        }
      } else {
        debugPrint('SonioxService: ⚠️ Received non-string message (type: ${message.runtimeType})');
      }
    } catch (e, stackTrace) {
      debugPrint('SonioxService: ✗ Error parsing message #$_messagesReceived');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (message is String) {
        debugPrint('Raw message that failed: $message');
      }
    }
  }

  /// Handle WebSocket errors
  void _handleError(error) {
    debugPrint('SonioxService: WebSocket error - $error');
    _updateStatus(ConnectionStatus.error);

    if (!_isManualDisconnect) {
      // Try to reconnect
      _scheduleReconnect('ar', 'en'); // Default languages
    }
  }

  /// Handle WebSocket disconnection
  void _handleDone() {
    debugPrint('SonioxService: WebSocket closed');

    if (_status == ConnectionStatus.connected) {
      _updateStatus(ConnectionStatus.disconnected);
    }

    if (!_isManualDisconnect && _reconnectAttempts < ApiConstants.maxReconnectAttempts) {
      _scheduleReconnect('ar', 'en'); // Default languages
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect(String languageA, String languageB) {
    if (_reconnectAttempts >= ApiConstants.maxReconnectAttempts) {
      debugPrint('SonioxService: Max reconnect attempts reached');
      _updateStatus(ConnectionStatus.error);
      return;
    }

    final delay = ApiConstants.reconnectDelaysMs[_reconnectAttempts];
    _reconnectAttempts++;

    debugPrint(
      'SonioxService: Reconnecting in ${delay}ms (attempt $_reconnectAttempts/${ApiConstants.maxReconnectAttempts})',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      connect(languageA: languageA, languageB: languageB);
    });
  }

  /// Update connection status
  void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _statusController?.add(newStatus);
  }

  /// Disconnect from Soniox
  Future<void> disconnect() async {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();

    if (_channel != null) {
      try {
        // Send empty frame to signal end of audio
        _channel!.sink.add(Uint8List(0));
        await Future.delayed(const Duration(milliseconds: 100));

        await _channel!.sink.close();
        debugPrint('SonioxService: Disconnected');
      } catch (e) {
        debugPrint('SonioxService: Error during disconnect - $e');
      }

      _channel = null;
    }

    _updateStatus(ConnectionStatus.disconnected);
    _reconnectAttempts = 0;

    // Clear language configuration
    _currentLanguageA = null;
    _currentLanguageB = null;
  }

  /// Dispose resources
  void dispose() {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _responseController?.close();
    _statusController?.close();

    debugPrint('SonioxService: Disposed');
  }

  /// Check if connected
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Reset reconnection attempts
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }
}
