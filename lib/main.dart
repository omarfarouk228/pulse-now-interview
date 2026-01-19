import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/market_data_provider.dart';
import 'services/websocket_service.dart';

void main() {
  runApp(const PulseNowApp());
}

class PulseNowApp extends StatefulWidget {
  const PulseNowApp({super.key});

  @override
  State<PulseNowApp> createState() => _PulseNowAppState();
}

class _PulseNowAppState extends State<PulseNowApp> with WidgetsBindingObserver {
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _marketDataSubscription;
  late MarketDataProvider _marketDataProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _marketDataProvider = MarketDataProvider();
    _initWebSocket();
  }

  void _initWebSocket() {
    _webSocketService.connect();

    _marketDataSubscription = _webSocketService.marketDataStream?.listen((
      marketData,
    ) {
      _marketDataProvider.updateMarketData(marketData);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Reconnect WebSocket when app comes to foreground
        if (!_webSocketService.isConnected) {
          _webSocketService.connect();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Optionally disconnect when app goes to background
        // _webSocketService.disconnect();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _marketDataSubscription?.cancel();
    _webSocketService.dispose();
    _marketDataProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _marketDataProvider,
      child: MaterialApp(
        title: 'PulseNow',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
