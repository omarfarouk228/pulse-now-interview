import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:pulsenow_flutter/services/api_service.dart';

void main() {
  group('ApiService', () {
    group('getMarketData', () {
      test('should return market data on successful response', () async {
        final mockData = [
          {'symbol': 'BTC/USD', 'price': 43250.50},
          {'symbol': 'ETH/USD', 'price': 2500.00},
        ];

        final client = MockClient((request) async {
          expect(request.url.path, '/api/market-data');
          return http.Response(json.encode({'data': mockData}), 200);
        });

        final apiService = ApiService(client: client);
        final result = await apiService.getMarketData();

        expect(result.length, 2);
        expect(result[0]['symbol'], 'BTC/USD');
        expect(result[1]['symbol'], 'ETH/USD');

        apiService.dispose();
      });

      test('should throw ApiException on 404', () async {
        final client = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final apiService = ApiService(client: client);

        expect(() => apiService.getMarketData(), throwsA(isA<ApiException>()));

        apiService.dispose();
      });

      test('should throw ApiException on 500', () async {
        final client = MockClient((request) async {
          return http.Response('Server Error', 500);
        });

        final apiService = ApiService(client: client);

        expect(
          () => apiService.getMarketData(),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
          ),
        );

        apiService.dispose();
      });
    });

    group('getMarketDataBySymbol', () {
      test('should return data for specific symbol', () async {
        final mockData = {
          'symbol': 'BTC/USD',
          'price': 43250.50,
          'change24h': 1250.25,
        };

        final client = MockClient((request) async {
          expect(request.url.path, contains('BTC/USD'));
          return http.Response(json.encode({'data': mockData}), 200);
        });

        final apiService = ApiService(client: client);
        final result = await apiService.getMarketDataBySymbol('BTC/USD');

        expect(result['symbol'], 'BTC/USD');
        expect(result['price'], 43250.50);

        apiService.dispose();
      });
    });

    group('getMarketHistory', () {
      test('should return history data with query parameters', () async {
        final mockData = [
          {'timestamp': '2024-01-15T10:00:00Z', 'close': 43000.0},
          {'timestamp': '2024-01-15T11:00:00Z', 'close': 43100.0},
        ];

        final client = MockClient((request) async {
          expect(request.url.queryParameters['timeframe'], '1h');
          expect(request.url.queryParameters['limit'], '50');
          return http.Response(json.encode({'data': mockData}), 200);
        });

        final apiService = ApiService(client: client);
        final result = await apiService.getMarketHistory(
          symbol: 'BTC/USD',
          timeframe: '1h',
          limit: 50,
        );

        expect(result.length, 2);

        apiService.dispose();
      });
    });

    group('getAnalyticsOverview', () {
      test('should return analytics overview', () async {
        final mockData = {
          'totalMarketCap': 1500000000000,
          'totalVolume': 50000000000,
        };

        final client = MockClient((request) async {
          expect(request.url.path, '/api/analytics/overview');
          return http.Response(json.encode({'data': mockData}), 200);
        });

        final apiService = ApiService(client: client);
        final result = await apiService.getAnalyticsOverview();

        expect(result['totalMarketCap'], 1500000000000);

        apiService.dispose();
      });
    });

    group('getPortfolio', () {
      test('should return portfolio summary', () async {
        final mockData = {'totalValue': 10000.0, 'totalPnL': 500.0};

        final client = MockClient((request) async {
          expect(request.url.path, '/api/portfolio');
          return http.Response(json.encode({'data': mockData}), 200);
        });

        final apiService = ApiService(client: client);
        final result = await apiService.getPortfolio();

        expect(result['totalValue'], 10000.0);

        apiService.dispose();
      });
    });

    group('error handling', () {
      test('should provide user-friendly error messages', () async {
        final testCases = [
          (400, 'Invalid request'),
          (401, 'Authentication required'),
          (403, 'Access denied'),
          (404, 'Data not found'),
          (429, 'Too many requests'),
          (500, 'Server error'),
          (502, 'temporarily unavailable'),
          (503, 'maintenance'),
        ];

        for (final (statusCode, expectedMessage) in testCases) {
          final client = MockClient((request) async {
            return http.Response('Error', statusCode);
          });

          final apiService = ApiService(client: client);

          try {
            await apiService.getMarketData();
            fail('Expected ApiException to be thrown');
          } on ApiException catch (e) {
            expect(
              e.message.toLowerCase(),
              contains(expectedMessage.toLowerCase()),
              reason: 'Status $statusCode should contain "$expectedMessage"',
            );
          }

          apiService.dispose();
        }
      });
    });
  });
}
