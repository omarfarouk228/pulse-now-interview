import 'package:flutter_test/flutter_test.dart';
import 'package:pulsenow_flutter/models/market_data_model.dart';

void main() {
  group('MarketData', () {
    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final json = {
          'symbol': 'BTC/USD',
          'price': 43250.50,
          'change24h': 1250.25,
          'changePercent24h': 2.5,
          'volume': 1250000000.0,
        };

        final marketData = MarketData.fromJson(json);

        expect(marketData.symbol, 'BTC/USD');
        expect(marketData.price, 43250.50);
        expect(marketData.change24h, 1250.25);
        expect(marketData.changePercent24h, 2.5);
        expect(marketData.volume, 1250000000.0);
      });

      test('should handle integer values', () {
        final json = {
          'symbol': 'ETH/USD',
          'price': 2500,
          'change24h': 50,
          'changePercent24h': 2,
          'volume': 500000000,
        };

        final marketData = MarketData.fromJson(json);

        expect(marketData.price, 2500.0);
        expect(marketData.change24h, 50.0);
        expect(marketData.changePercent24h, 2.0);
        expect(marketData.volume, 500000000.0);
      });

      test('should handle string values', () {
        final json = {
          'symbol': 'SOL/USD',
          'price': '100.50',
          'change24h': '5.25',
          'changePercent24h': '5.5',
          'volume': '1000000',
        };

        final marketData = MarketData.fromJson(json);

        expect(marketData.price, 100.50);
        expect(marketData.change24h, 5.25);
        expect(marketData.changePercent24h, 5.5);
        expect(marketData.volume, 1000000.0);
      });

      test('should handle null values with defaults', () {
        final json = <String, dynamic>{
          'symbol': null,
          'price': null,
          'change24h': null,
          'changePercent24h': null,
          'volume': null,
        };

        final marketData = MarketData.fromJson(json);

        expect(marketData.symbol, '');
        expect(marketData.price, 0.0);
        expect(marketData.change24h, 0.0);
        expect(marketData.changePercent24h, 0.0);
        expect(marketData.volume, 0.0);
      });

      test('should parse optional fields when present', () {
        final json = {
          'symbol': 'BTC/USD',
          'price': 43250.50,
          'change24h': 1250.25,
          'changePercent24h': 2.5,
          'volume': 1250000000.0,
          'high24h': 44000.0,
          'low24h': 42000.0,
          'marketCap': 850000000000.0,
          'lastUpdated': '2024-01-15T10:30:00Z',
        };

        final marketData = MarketData.fromJson(json);

        expect(marketData.high24h, 44000.0);
        expect(marketData.low24h, 42000.0);
        expect(marketData.marketCap, 850000000000.0);
        expect(marketData.lastUpdated, isA<DateTime>());
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        const marketData = MarketData(
          symbol: 'BTC/USD',
          price: 43250.50,
          change24h: 1250.25,
          changePercent24h: 2.5,
          volume: 1250000000.0,
        );

        final json = marketData.toJson();

        expect(json['symbol'], 'BTC/USD');
        expect(json['price'], 43250.50);
        expect(json['change24h'], 1250.25);
        expect(json['changePercent24h'], 2.5);
        expect(json['volume'], 1250000000.0);
      });
    });

    group('isPositiveChange', () {
      test('should return true for positive change', () {
        const marketData = MarketData(
          symbol: 'BTC/USD',
          price: 43250.50,
          change24h: 1250.25,
          changePercent24h: 2.5,
          volume: 1250000000.0,
        );

        expect(marketData.isPositiveChange, true);
      });

      test('should return true for zero change', () {
        const marketData = MarketData(
          symbol: 'BTC/USD',
          price: 43250.50,
          change24h: 0.0,
          changePercent24h: 0.0,
          volume: 1250000000.0,
        );

        expect(marketData.isPositiveChange, true);
      });

      test('should return false for negative change', () {
        const marketData = MarketData(
          symbol: 'BTC/USD',
          price: 43250.50,
          change24h: -1250.25,
          changePercent24h: -2.5,
          volume: 1250000000.0,
        );

        expect(marketData.isPositiveChange, false);
      });
    });

    group('baseCurrency and quoteCurrency', () {
      test('should extract base and quote currencies correctly', () {
        const marketData = MarketData(
          symbol: 'BTC/USD',
          price: 43250.50,
          change24h: 0.0,
          changePercent24h: 0.0,
          volume: 0.0,
        );

        expect(marketData.baseCurrency, 'BTC');
        expect(marketData.quoteCurrency, 'USD');
      });

      test('should handle symbol without separator', () {
        const marketData = MarketData(
          symbol: 'BTCUSD',
          price: 43250.50,
          change24h: 0.0,
          changePercent24h: 0.0,
          volume: 0.0,
        );

        expect(marketData.baseCurrency, 'BTCUSD');
        expect(marketData.quoteCurrency, 'USD');
      });
    });

    group('copyWith', () {
      test('should create a copy with updated fields', () {
        const original = MarketData(
          symbol: 'BTC/USD',
          price: 43250.50,
          change24h: 1250.25,
          changePercent24h: 2.5,
          volume: 1250000000.0,
        );

        final updated = original.copyWith(
          price: 44000.0,
          changePercent24h: 3.0,
        );

        expect(updated.symbol, 'BTC/USD');
        expect(updated.price, 44000.0);
        expect(updated.change24h, 1250.25);
        expect(updated.changePercent24h, 3.0);
        expect(updated.volume, 1250000000.0);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        const a = MarketData(
          symbol: 'BTC/USD',
          price: 43250.50,
          change24h: 1250.25,
          changePercent24h: 2.5,
          volume: 1250000000.0,
        );

        const b = MarketData(
          symbol: 'BTC/USD',
          price: 43250.50,
          change24h: 1250.25,
          changePercent24h: 2.5,
          volume: 1250000000.0,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('should not be equal for different values', () {
        const a = MarketData(
          symbol: 'BTC/USD',
          price: 43250.50,
          change24h: 1250.25,
          changePercent24h: 2.5,
          volume: 1250000000.0,
        );

        const b = MarketData(
          symbol: 'ETH/USD',
          price: 2500.0,
          change24h: 50.0,
          changePercent24h: 2.0,
          volume: 500000000.0,
        );

        expect(a, isNot(equals(b)));
      });
    });
  });
}
