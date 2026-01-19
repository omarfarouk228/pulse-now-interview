import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:pulsenow_flutter/providers/market_data_provider.dart';
import 'package:pulsenow_flutter/services/api_service.dart';
import 'package:pulsenow_flutter/models/market_data_model.dart';

void main() {
  group('MarketDataProvider', () {
    late MarketDataProvider provider;
    late MockClient mockClient;

    final mockMarketData = [
      {
        'symbol': 'BTC/USD',
        'price': 43250.50,
        'change24h': 1250.25,
        'changePercent24h': 2.5,
        'volume': 1250000000.0,
      },
      {
        'symbol': 'ETH/USD',
        'price': 2500.00,
        'change24h': -50.00,
        'changePercent24h': -1.5,
        'volume': 500000000.0,
      },
      {
        'symbol': 'SOL/USD',
        'price': 100.00,
        'change24h': 5.00,
        'changePercent24h': 5.0,
        'volume': 100000000.0,
      },
    ];

    setUp(() {
      mockClient = MockClient((request) async {
        if (request.url.path == '/api/market-data') {
          return http.Response(json.encode({'data': mockMarketData}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      provider = MarketDataProvider(apiService: apiService);
    });

    tearDown(() {
      provider.dispose();
    });

    group('initial state', () {
      test('should have empty market data', () {
        expect(provider.marketData, isEmpty);
      });

      test('should not be loading', () {
        expect(provider.isLoading, false);
      });

      test('should have no error', () {
        expect(provider.error, isNull);
      });

      test('should have default sort option', () {
        expect(provider.sortOption, MarketDataSortOption.symbol);
      });
    });

    group('loadMarketData', () {
      test('should load market data successfully', () async {
        await provider.loadMarketData();

        expect(provider.marketData.length, 3);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
        expect(provider.hasData, true);
      });

      test('should set loading state during fetch', () async {
        final loadingStates = <bool>[];

        provider.addListener(() {
          loadingStates.add(provider.isLoading);
        });

        await provider.loadMarketData();

        expect(loadingStates, contains(true));
        expect(loadingStates.last, false);
      });

      test('should handle API errors', () async {
        final errorClient = MockClient((request) async {
          return http.Response('Server Error', 500);
        });

        final errorApiService = ApiService(client: errorClient);
        final errorProvider = MarketDataProvider(apiService: errorApiService);

        await errorProvider.loadMarketData();

        expect(errorProvider.error, isNotNull);
        expect(errorProvider.isLoading, false);
        expect(errorProvider.hasError, true);

        errorProvider.dispose();
      });
    });

    group('sorting', () {
      test('should sort by symbol (default)', () async {
        await provider.loadMarketData();

        final symbols = provider.marketData.map((d) => d.symbol).toList();
        expect(symbols, ['BTC/USD', 'ETH/USD', 'SOL/USD']);
      });

      test('should sort by price descending', () async {
        await provider.loadMarketData();
        provider.setSortOption(MarketDataSortOption.priceDesc);

        final prices = provider.marketData.map((d) => d.price).toList();
        expect(prices, [43250.50, 2500.00, 100.00]);
      });

      test('should sort by price ascending', () async {
        await provider.loadMarketData();
        provider.setSortOption(MarketDataSortOption.priceAsc);

        final prices = provider.marketData.map((d) => d.price).toList();
        expect(prices, [100.00, 2500.00, 43250.50]);
      });

      test('should sort by change descending (best gainers)', () async {
        await provider.loadMarketData();
        provider.setSortOption(MarketDataSortOption.changeDesc);

        final changes = provider.marketData
            .map((d) => d.changePercent24h)
            .toList();
        expect(changes, [5.0, 2.5, -1.5]);
      });

      test('should sort by change ascending (worst losers)', () async {
        await provider.loadMarketData();
        provider.setSortOption(MarketDataSortOption.changeAsc);

        final changes = provider.marketData
            .map((d) => d.changePercent24h)
            .toList();
        expect(changes, [-1.5, 2.5, 5.0]);
      });
    });

    group('search/filter', () {
      test('should filter by search query', () async {
        await provider.loadMarketData();
        provider.setSearchQuery('BTC');

        expect(provider.marketData.length, 1);
        expect(provider.marketData.first.symbol, 'BTC/USD');
      });

      test('should be case insensitive', () async {
        await provider.loadMarketData();
        provider.setSearchQuery('btc');

        expect(provider.marketData.length, 1);
        expect(provider.marketData.first.symbol, 'BTC/USD');
      });

      test('should return all data when search is cleared', () async {
        await provider.loadMarketData();
        provider.setSearchQuery('BTC');
        provider.clearSearch();

        expect(provider.marketData.length, 3);
      });
    });

    group('updateMarketData', () {
      test('should update existing market data', () async {
        await provider.loadMarketData();

        const updatedData = MarketData(
          symbol: 'BTC/USD',
          price: 45000.00,
          change24h: 2000.00,
          changePercent24h: 4.5,
          volume: 1300000000.0,
        );

        provider.updateMarketData(updatedData);

        final btcData = provider.getBySymbol('BTC/USD');
        expect(btcData?.price, 45000.00);
        expect(btcData?.changePercent24h, 4.5);
      });

      test('should not add new market data if symbol not found', () async {
        await provider.loadMarketData();

        const newData = MarketData(
          symbol: 'DOGE/USD',
          price: 0.10,
          change24h: 0.01,
          changePercent24h: 10.0,
          volume: 50000000.0,
        );

        provider.updateMarketData(newData);

        expect(provider.getBySymbol('DOGE/USD'), isNull);
        expect(provider.marketData.length, 3);
      });
    });

    group('helper methods', () {
      test(
        'getTopGainers should return positive changes sorted by best',
        () async {
          await provider.loadMarketData();

          final gainers = provider.getTopGainers(limit: 2);

          expect(gainers.length, 2);
          expect(gainers.first.changePercent24h, 5.0); // SOL
          expect(gainers[1].changePercent24h, 2.5); // BTC
        },
      );

      test(
        'getTopLosers should return negative changes sorted by worst',
        () async {
          await provider.loadMarketData();

          final losers = provider.getTopLosers(limit: 2);

          expect(losers.length, 1); // Only ETH is negative
          expect(losers.first.changePercent24h, -1.5);
        },
      );

      test('getBySymbol should return correct market data', () async {
        await provider.loadMarketData();

        final data = provider.getBySymbol('ETH/USD');

        expect(data, isNotNull);
        expect(data?.symbol, 'ETH/USD');
        expect(data?.price, 2500.00);
      });

      test('getBySymbol should return null for unknown symbol', () async {
        await provider.loadMarketData();

        final data = provider.getBySymbol('UNKNOWN/USD');

        expect(data, isNull);
      });
    });
  });
}
