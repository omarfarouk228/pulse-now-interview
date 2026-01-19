import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulsenow_flutter/providers/market_data_provider.dart';
import 'package:pulsenow_flutter/screens/market_data_screen.dart';
import 'package:pulsenow_flutter/models/market_data_model.dart';

/// A mock provider for testing widgets.
class MockMarketDataProvider extends ChangeNotifier
    implements MarketDataProvider {
  List<MarketData> _marketData = [];
  bool _isLoading = false;
  String? _error;

  @override
  List<MarketData> get marketData => _marketData;

  @override
  List<MarketData> get allMarketData => _marketData;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  String get searchQuery => '';

  @override
  MarketDataSortOption get sortOption => MarketDataSortOption.symbol;

  @override
  MarketData? get selectedMarketData => null;

  @override
  bool get hasData => _marketData.isNotEmpty;

  @override
  bool get hasError => _error != null;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setMarketData(List<MarketData> data) {
    _marketData = data;
    notifyListeners();
  }

  @override
  Future<void> loadMarketData() async {
    // Mock implementation
  }

  @override
  Future<void> refreshMarketData() async {
    // Mock implementation
  }

  @override
  void setSearchQuery(String query) {}

  @override
  void clearSearch() {}

  @override
  void setSortOption(MarketDataSortOption option) {}

  @override
  void selectMarketData(MarketData? data) {}

  @override
  void clearSelection() {}

  @override
  void updateMarketData(MarketData updatedData) {}

  @override
  void updateMultipleMarketData(List<MarketData> updates) {}

  @override
  void clearError() {}

  @override
  MarketData? getBySymbol(String symbol) => null;

  @override
  List<MarketData> getTopGainers({int limit = 5}) => [];

  @override
  List<MarketData> getTopLosers({int limit = 5}) => [];
}

void main() {
  group('MarketDataScreen Widget Tests', () {
    testWidgets('should show loading indicator when loading', (tester) async {
      final provider = MockMarketDataProvider()..setLoading(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MarketDataProvider>.value(
            value: provider,
            child: const Scaffold(body: MarketDataScreen()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading market data...'), findsOneWidget);
    });

    testWidgets('should show error message when error occurs', (tester) async {
      final provider = MockMarketDataProvider()..setError('Test error message');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MarketDataProvider>.value(
            value: provider,
            child: const Scaffold(body: MarketDataScreen()),
          ),
        ),
      );

      expect(find.text('Oops! Something went wrong'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('should show market data list when data is loaded', (
      tester,
    ) async {
      final provider = MockMarketDataProvider()
        ..setMarketData([
          const MarketData(
            symbol: 'BTC/USD',
            price: 43250.50,
            change24h: 1250.25,
            changePercent24h: 2.5,
            volume: 1250000000.0,
          ),
          const MarketData(
            symbol: 'ETH/USD',
            price: 2500.00,
            change24h: -50.00,
            changePercent24h: -1.5,
            volume: 500000000.0,
          ),
        ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MarketDataProvider>.value(
            value: provider,
            child: const Scaffold(body: MarketDataScreen()),
          ),
        ),
      );

      expect(find.text('BTC/USD'), findsOneWidget);
      expect(find.text('ETH/USD'), findsOneWidget);
    });

    testWidgets('should show color-coded percentage changes', (tester) async {
      final provider = MockMarketDataProvider()
        ..setMarketData([
          const MarketData(
            symbol: 'BTC/USD',
            price: 43250.50,
            change24h: 1250.25,
            changePercent24h: 2.5,
            volume: 1250000000.0,
          ),
          const MarketData(
            symbol: 'ETH/USD',
            price: 2500.00,
            change24h: -50.00,
            changePercent24h: -1.5,
            volume: 500000000.0,
          ),
        ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MarketDataProvider>.value(
            value: provider,
            child: const Scaffold(body: MarketDataScreen()),
          ),
        ),
      );

      // Check that percentages are displayed with correct signs
      expect(find.text('+2.50%'), findsOneWidget);
      expect(find.text('-1.50%'), findsOneWidget);
    });

    testWidgets('should show empty state when no data', (tester) async {
      final provider = MockMarketDataProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MarketDataProvider>.value(
            value: provider,
            child: const Scaffold(body: MarketDataScreen()),
          ),
        ),
      );

      expect(find.text('No Market Data'), findsOneWidget);
      expect(find.text('Load Data'), findsOneWidget);
    });
  });
}
