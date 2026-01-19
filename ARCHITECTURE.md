# Technical Architecture - PulseNow

This document details the technical architecture of the PulseNow application to facilitate code understanding.

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Screens   │  │   Screens   │  │   Screens   │             │
│  │  (Markets)  │  │ (Analytics) │  │ (Portfolio) │             │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │
│         │                │                │                     │
│         └────────────────┼────────────────┘                     │
│                          │                                      │
│                          ▼                                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Providers (State)                     │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │   │
│  │  │MarketData   │ │Analytics    │ │Portfolio    │        │   │
│  │  │Provider     │ │Provider     │ │Provider     │        │   │
│  │  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘        │   │
│  └─────────┼───────────────┼───────────────┼───────────────┘   │
│            │               │               │                    │
│            └───────────────┼───────────────┘                    │
│                            ▼                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      Services                            │   │
│  │  ┌─────────────────┐    ┌─────────────────────┐         │   │
│  │  │   ApiService    │    │  WebSocketService   │         │   │
│  │  │    (REST)       │    │   (Real-time)       │         │   │
│  │  └────────┬────────┘    └──────────┬──────────┘         │   │
│  └───────────┼────────────────────────┼────────────────────┘   │
│              │                        │                         │
└──────────────┼────────────────────────┼─────────────────────────┘
               │                        │
               ▼                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                        Backend Node.js                            │
│  ┌────────────────────┐    ┌────────────────────┐                │
│  │   REST API         │    │   WebSocket Server │                │
│  │   Port 3000        │    │   Port 3000        │                │
│  └────────────────────┘    └────────────────────┘                │
└──────────────────────────────────────────────────────────────────┘
```

## Application Layers

### 1. Presentation Layer (Screens)

Screens are `StatelessWidget` or `StatefulWidget` that consume data via `Consumer<Provider>`.

#### MarketDataScreen

```dart
// Responsibilities:
// - Display market list
// - Handle search and sorting
// - Navigate to detail view

Consumer<MarketDataProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) return LoadingWidget();
    if (provider.hasError) return ErrorWidget(onRetry: provider.loadMarketData);
    return ListView.builder(...);
  },
)
```

#### MarketDetailScreen

```dart
// Responsibilities:
// - Display market details
// - Receive real-time updates
// - Show price history
```

#### AnalyticsScreen

```dart
// Responsibilities:
// - Dashboard with market overview
// - Market trends with timeframe selection
// - Market sentiment analysis
```

#### PortfolioScreen

```dart
// Responsibilities:
// - Portfolio summary (total value, P&L)
// - Holdings list
// - Performance metrics
```

### 2. State Layer (Providers)

Each Provider extends `ChangeNotifier` and manages a specific domain.

#### MarketDataProvider

```dart
class MarketDataProvider extends ChangeNotifier {
  // State
  List<MarketData> _marketData = [];
  List<MarketData> _filteredData = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  MarketDataSortOption _sortOption = MarketDataSortOption.symbol;

  // Actions
  Future<void> loadMarketData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _marketData = await _apiService.getMarketData();
      _applyFiltersAndSort();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Real-time update (called by WebSocket)
  void updateMarketData(MarketData updatedData) {
    final index = _marketData.indexWhere((m) => m.symbol == updatedData.symbol);
    if (index != -1) {
      _marketData[index] = updatedData;
      _applyFiltersAndSort();
      notifyListeners();
    }
  }
}
```

#### Data Flow

```
┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│   API Call   │────▶│   Provider  │────▶│    Screen    │
└──────────────┘     │   (State)   │     │     (UI)     │
                     └──────┬──────┘     └──────────────┘
                            │
                            │ notifyListeners()
                            │
┌──────────────┐            │
│  WebSocket   │────────────┘
│   Update     │
└──────────────┘
```

### 3. Services Layer

#### ApiService

```dart
class ApiService {
  final String baseUrl;
  final http.Client _client;

  // Generic method for GET requests
  Future<T> _get<T>(String endpoint, T Function(dynamic) parser) async {
    final response = await _client.get(Uri.parse('$baseUrl$endpoint'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return parser(data);
    }

    throw ApiException(_getErrorMessage(response.statusCode), response.statusCode);
  }

  // Specific endpoints
  Future<List<MarketData>> getMarketData() =>
    _get('/market-data', (data) => (data as List).map(MarketData.fromJson).toList());
}
```

#### WebSocketService

```dart
class WebSocketService {
  WebSocketChannel? _channel;
  final _marketDataController = StreamController<MarketData>.broadcast();
  final _stateController = StreamController<WebSocketState>.broadcast();

  // Connection states
  enum WebSocketState { disconnected, connecting, connected, reconnecting, error }

  // Auto-reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());
    _reconnectTimer = Timer(delay, connect);
    _reconnectAttempts++;
  }

  // Stream for updates
  Stream<MarketData> get marketDataStream => _marketDataController.stream;
}
```

### 4. Models Layer

#### MarketData (Immutable)

```dart
@immutable
class MarketData {
  final String symbol;
  final double price;
  final double change24h;
  final double changePercent24h;
  final double volume;
  final double? high24h;
  final double? low24h;
  final double? marketCap;
  final DateTime? lastUpdated;

  // Factory for JSON parsing with null safety handling
  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      symbol: json['symbol'] as String,
      price: _parseDouble(json['price']),
      change24h: _parseDouble(json['change24h']),
      // ...
    );
  }

  // Helper for safe parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // CopyWith for immutable updates
  MarketData copyWith({double? price, ...}) {
    return MarketData(
      symbol: symbol,
      price: price ?? this.price,
      // ...
    );
  }
}
```

## Lifecycle Management

### Initialization (main.dart)

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const PulseNowApp(),
    ),
  );
}
```

### App Lifecycle Handling

```dart
class _PulseNowAppState extends State<PulseNowApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebSocket();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Reconnect WebSocket on resume
        _websocketService.connect();
        break;
      case AppLifecycleState.paused:
        // Optional: disconnect to save battery
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _websocketService.dispose();
    super.dispose();
  }
}
```

## Navigation

### Route Configuration

```dart
class AppRouter {
  static const String home = '/';
  static const String markets = '/markets';
  static const String marketDetail = '/market-detail';
  static const String analytics = '/analytics';
  static const String portfolio = '/portfolio';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case marketDetail:
        final marketData = settings.arguments as MarketData;
        return MaterialPageRoute(
          builder: (_) => MarketDetailScreen(marketData: marketData),
        );
      // ...
    }
  }
}
```

### Bottom Navigation

```dart
class MainShell extends StatefulWidget {
  // IndexedStack to preserve tab state
  IndexedStack(
    index: _currentIndex,
    children: [
      MarketDataScreen(),
      AnalyticsScreen(),
      PortfolioScreen(),
    ],
  )
}
```

## Error Handling

### Exception Hierarchy

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  static String getMessageForStatusCode(int code) {
    switch (code) {
      case 400: return 'Bad request';
      case 401: return 'Unauthorized';
      case 403: return 'Access denied';
      case 404: return 'Resource not found';
      case 500: return 'Server error';
      default: return 'Unknown error';
    }
  }
}
```

### Error Propagation

```
Service Layer          Provider Layer         UI Layer
     │                       │                    │
     │  ApiException         │                    │
     ├──────────────────────▶│                    │
     │                       │  _error = message  │
     │                       ├───────────────────▶│
     │                       │  notifyListeners() │
     │                       │                    │
     │                       │                    │ ErrorWidget
     │                       │                    │ with Retry
```

## Testing

### Test Structure

```
test/
├── models/
│   └── market_data_model_test.dart   # Serialization tests
├── providers/
│   └── market_data_provider_test.dart # State management tests
├── services/
│   └── api_service_test.dart          # Tests with MockClient
└── widget_test.dart                   # UI integration tests
```

### Provider Test Example

```dart
void main() {
  group('MarketDataProvider', () {
    late MarketDataProvider provider;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      provider = MarketDataProvider(apiService: mockApiService);
    });

    test('loadMarketData updates state correctly', () async {
      when(mockApiService.getMarketData())
          .thenAnswer((_) async => [mockMarketData]);

      await provider.loadMarketData();

      expect(provider.isLoading, false);
      expect(provider.marketData.length, 1);
      expect(provider.error, null);
    });
  });
}
```

## Best Practices Applied

### 1. Immutability

- Models with `@immutable`
- `copyWith` for updates
- No direct list mutation

### 2. Null Safety

- Non-nullable types by default
- `?` operator for optionals
- `??` operator for default values

### 3. Separation of Concerns

- Models: Data structure
- Services: External communication
- Providers: Business logic and state
- Screens: UI presentation

### 4. Dependency Injection

- Injectable services via constructor
- Facilitates testing with mocks
- Component decoupling

### 5. Resource Management

- `dispose()` on all controllers
- Subscription cancellation
- Timer cleanup

## Performance

### Implemented Optimizations

1. **ListView.builder**: Lazy item rendering
2. **const constructors**: Immutable widgets
3. **Selective rebuilds**: Targeted Consumer on required data
4. **Debounced search**: Prevents excessive API calls
5. **IndexedStack**: Preserves tab state

## Conclusion

This architecture follows SOLID principles and Flutter/Dart best practices for a maintainable, testable, and performant application. The clear layer separation allows for easy code evolution and facilitates team collaboration.
