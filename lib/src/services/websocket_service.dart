import 'dart:async';
import 'package:enterprise_attendance/src/config/app_config.dart';
import 'package:enterprise_attendance/src/services/logger_service.dart';

/// WebSocketService for real-time presence and chat streams.
///
/// Uses centralized configuration for WebSocket URL.
class WebSocketService {
  // Use centralized configuration
  String get _wsUrl => AppConfig.webSocketUrl;

  final StreamController<Map<String, dynamic>> _presenceController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _chatController =
      StreamController.broadcast();

  Timer? _presenceTimer;
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  void connect() {
    if (_isConnected) return;

    try {
      AppLogger.info('WebSocketService', 'Connecting to WebSocket',
          context: {'url': _wsUrl});

      // In mock mode, simulate presence pings
      if (AppConfig.useMockData) {
        _presenceTimer = Timer.periodic(const Duration(seconds: 5), (t) {
          if (!_presenceController.isClosed) {
            _presenceController.add({
              'type': 'presence',
              'userId': 'u_jane',
              'status': 'online',
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            });
          }
        });
        _isConnected = true;
        AppLogger.info('WebSocketService', 'Mock WebSocket connected');
      } else {
        // Note: Real WebSocket connection using web_socket_channel to be implemented
        // final channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
        // ... handle real WebSocket connection
        AppLogger.warning(
            'WebSocketService', 'Real WebSocket not yet implemented');
      }
    } catch (e, stack) {
      AppLogger.error('WebSocketService', 'Failed to connect',
          error: e, stackTrace: stack);
      _isConnected = false;
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _isConnected = false;
    AppLogger.info('WebSocketService', 'Disconnected');
  }

  /// Send a chat message
  void sendChat(String channelId, String from, String message) {
    try {
      final payload = {
        'channel': channelId,
        'from': from,
        'message': message,
        'ts': DateTime.now().toUtc().toIso8601String(),
      };

      if (!_chatController.isClosed) {
        _chatController.add(payload);
      }

      AppLogger.debug('WebSocketService', 'Chat message sent', context: {
        'channel': channelId,
        'from': from,
      });
    } catch (e, stack) {
      AppLogger.error('WebSocketService', 'Failed to send chat',
          error: e, stackTrace: stack);
    }
  }

  /// Send presence update
  void sendPresence(String userId, String status) {
    try {
      final payload = {
        'type': 'presence',
        'userId': userId,
        'status': status,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      if (!_presenceController.isClosed) {
        _presenceController.add(payload);
      }
    } catch (e, stack) {
      AppLogger.error('WebSocketService', 'Failed to send presence',
          error: e, stackTrace: stack);
    }
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
    _presenceController.close();
    _chatController.close();
    AppLogger.info('WebSocketService', 'Disposed');
  }
}
