import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/constants.dart';
import '../models/market_data_model.dart';

/// Enum representing WebSocket connection states.
enum WebSocketState { disconnected, connecting, connected, reconnecting, error }

/// Service for managing WebSocket connections for real-time market updates.
///
/// Provides automatic reconnection and message parsing.
class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<MarketData>? _marketDataController;
  StreamController<WebSocketState>? _stateController;

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);

  WebSocketState _state = WebSocketState.disconnected;
  bool _shouldReconnect = true;

  /// Stream of market data updates.
  Stream<MarketData>? get marketDataStream => _marketDataController?.stream;

  /// Stream of connection state changes.
  Stream<WebSocketState>? get stateStream => _stateController?.stream;

  /// Current connection state.
  WebSocketState get state => _state;

  /// Whether the WebSocket is currently connected.
  bool get isConnected => _state == WebSocketState.connected;

  /// Connects to the WebSocket server.
  void connect() {
    if (_state == WebSocketState.connecting ||
        _state == WebSocketState.connected) {
      return;
    }

    _shouldReconnect = true;
    _initControllers();
    _doConnect();
  }

  void _initControllers() {
    _marketDataController?.close();
    _stateController?.close();
    _marketDataController = StreamController<MarketData>.broadcast();
    _stateController = StreamController<WebSocketState>.broadcast();
  }

  void _doConnect() {
    _updateState(WebSocketState.connecting);

    try {
      final uri = Uri.parse(AppConstants.wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Assume connected after channel is created
      // In production, you might want to wait for a "connected" message
      _updateState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _startPingTimer();

      debugPrint('WebSocket: Connected to ${AppConstants.wsUrl}');
    } catch (e) {
      debugPrint('WebSocket: Connection error - $e');
      _handleConnectionError();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = json.decode(message as String);

      if (data is Map<String, dynamic>) {
        // Handle different message types
        final type = data['type'] as String?;

        switch (type) {
          case 'market_update':
          case 'price_update':
            final marketData = data['data'] as Map<String, dynamic>?;
            if (marketData != null) {
              _marketDataController?.add(MarketData.fromJson(marketData));
            }
            break;
          case 'batch_update':
            final updates = data['data'] as List?;
            if (updates != null) {
              for (final update in updates) {
                if (update is Map<String, dynamic>) {
                  _marketDataController?.add(MarketData.fromJson(update));
                }
              }
            }
            break;
          case 'pong':
            // Server responded to ping
            break;
          default:
            // Unknown message type, try to parse as market data
            if (data.containsKey('symbol')) {
              _marketDataController?.add(MarketData.fromJson(data));
            }
        }
      }
    } catch (e) {
      debugPrint('WebSocket: Error parsing message - $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('WebSocket: Error - $error');
    _handleConnectionError();
  }

  void _onDone() {
    debugPrint('WebSocket: Connection closed');
    _stopPingTimer();

    if (_shouldReconnect) {
      _scheduleReconnect();
    } else {
      _updateState(WebSocketState.disconnected);
    }
  }

  void _handleConnectionError() {
    _updateState(WebSocketState.error);
    _stopPingTimer();

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnect attempts reached');
      _updateState(WebSocketState.error);
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    final delay = _reconnectDelay * _reconnectAttempts;
    debugPrint(
      'WebSocket: Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)',
    );

    _updateState(WebSocketState.reconnecting);

    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect) {
        _doConnect();
      }
    });
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _sendPing();
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _sendPing() {
    if (isConnected) {
      try {
        _channel?.sink.add(json.encode({'type': 'ping'}));
      } catch (e) {
        debugPrint('WebSocket: Error sending ping - $e');
      }
    }
  }

  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController?.add(newState);
    }
  }

  /// Subscribes to updates for specific symbols.
  void subscribe(List<String> symbols) {
    if (isConnected && symbols.isNotEmpty) {
      try {
        _channel?.sink.add(
          json.encode({'type': 'subscribe', 'symbols': symbols}),
        );
      } catch (e) {
        debugPrint('WebSocket: Error subscribing - $e');
      }
    }
  }

  /// Unsubscribes from updates for specific symbols.
  void unsubscribe(List<String> symbols) {
    if (isConnected && symbols.isNotEmpty) {
      try {
        _channel?.sink.add(
          json.encode({'type': 'unsubscribe', 'symbols': symbols}),
        );
      } catch (e) {
        debugPrint('WebSocket: Error unsubscribing - $e');
      }
    }
  }

  /// Disconnects from the WebSocket server.
  void disconnect() {
    _shouldReconnect = false;
    _stopPingTimer();
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    _channel?.sink.close();
    _channel = null;

    _updateState(WebSocketState.disconnected);
    debugPrint('WebSocket: Disconnected');
  }

  /// Disposes all resources.
  void dispose() {
    disconnect();
    _marketDataController?.close();
    _stateController?.close();
    _marketDataController = null;
    _stateController = null;
  }
}
