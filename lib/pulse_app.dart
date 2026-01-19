import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulsenow_flutter/providers/analytics_provider.dart';
import 'package:pulsenow_flutter/providers/market_data_provider.dart';
import 'package:pulsenow_flutter/providers/portfolio_provider.dart';
import 'package:pulsenow_flutter/providers/theme_provider.dart';
import 'package:pulsenow_flutter/router/app_router.dart';
import 'package:pulsenow_flutter/services/websocket_service.dart';
import 'package:pulsenow_flutter/themes/app_theme.dart';

class PulseNowApp extends StatefulWidget {
  const PulseNowApp({super.key});

  @override
  State<PulseNowApp> createState() => _PulseNowAppState();
}

class _PulseNowAppState extends State<PulseNowApp> with WidgetsBindingObserver {
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _marketDataSubscription;
  late MarketDataProvider _marketDataProvider;
  final AnalyticsProvider _analyticsProvider = AnalyticsProvider();
  final PortfolioProvider _portfolioProvider = PortfolioProvider();
  final ThemeProvider _themeProvider = ThemeProvider();

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
        if (!_webSocketService.isConnected) {
          _webSocketService.connect();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _marketDataProvider),
        ChangeNotifierProvider.value(value: _analyticsProvider),
        ChangeNotifierProvider.value(value: _portfolioProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'PulseNow',
            navigatorKey: AppRouter.navigatorKey,
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: AppRoutes.home,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
