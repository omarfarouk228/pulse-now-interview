import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Custom exception for API-related errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  const ApiException(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status: $statusCode)';
    }
    return 'ApiException: $message';
  }
}

/// Service class for handling all API communications with the backend.
///
/// Provides methods for fetching market data, analytics, and portfolio information.
class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 30);

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches all market data from the API.
  ///
  /// Returns a list of market data maps containing symbol, price, and change info.
  /// Throws [ApiException] if the request fails.
  Future<List<Map<String, dynamic>>> getMarketData() async {
    return _get<List<Map<String, dynamic>>>(
      AppConstants.marketDataEndpoint,
      parser: (data) => List<Map<String, dynamic>>.from(data as List),
    );
  }

  /// Fetches market data for a specific symbol.
  ///
  /// [symbol] - The trading pair symbol (e.g., "BTC/USD")
  Future<Map<String, dynamic>> getMarketDataBySymbol(String symbol) async {
    return _get<Map<String, dynamic>>(
      '${AppConstants.marketDataEndpoint}/$symbol',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  /// Fetches historical market data for a symbol.
  ///
  /// [symbol] - The trading pair symbol
  /// [timeframe] - Time interval (e.g., "1h", "4h", "1d")
  /// [limit] - Maximum number of data points to return
  Future<List<Map<String, dynamic>>> getMarketHistory({
    required String symbol,
    String timeframe = '1h',
    int limit = 100,
  }) async {
    return _get<List<Map<String, dynamic>>>(
      '${AppConstants.marketDataEndpoint}/$symbol/history',
      queryParams: {'timeframe': timeframe, 'limit': limit.toString()},
      parser: (data) => List<Map<String, dynamic>>.from(data as List),
    );
  }

  /// Fetches analytics overview data.
  Future<Map<String, dynamic>> getAnalyticsOverview() async {
    return _get<Map<String, dynamic>>(
      '${AppConstants.analyticsEndpoint}/overview',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  /// Fetches market trends data.
  ///
  /// [timeframe] - Time period for trends (e.g., "24h", "7d")
  Future<Map<String, dynamic>> getMarketTrends({
    String timeframe = '24h',
  }) async {
    return _get<Map<String, dynamic>>(
      '${AppConstants.analyticsEndpoint}/trends',
      queryParams: {'timeframe': timeframe},
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  /// Fetches market sentiment data.
  Future<Map<String, dynamic>> getMarketSentiment() async {
    return _get<Map<String, dynamic>>(
      '${AppConstants.analyticsEndpoint}/sentiment',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  /// Fetches portfolio summary.
  Future<Map<String, dynamic>> getPortfolio() async {
    return _get<Map<String, dynamic>>(
      AppConstants.portfolioEndpoint,
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  /// Fetches portfolio holdings.
  Future<List<Map<String, dynamic>>> getPortfolioHoldings() async {
    return _get<List<Map<String, dynamic>>>(
      '${AppConstants.portfolioEndpoint}/holdings',
      parser: (data) => List<Map<String, dynamic>>.from(data as List),
    );
  }

  /// Fetches portfolio performance metrics.
  ///
  /// [timeframe] - Time period for performance (e.g., "7d", "30d")
  Future<Map<String, dynamic>> getPortfolioPerformance({
    String timeframe = '7d',
  }) async {
    return _get<Map<String, dynamic>>(
      '${AppConstants.portfolioEndpoint}/performance',
      queryParams: {'timeframe': timeframe},
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  /// Generic GET request handler with error handling.
  Future<T> _get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    required T Function(dynamic data) parser,
  }) async {
    final uri = _buildUri(endpoint, queryParams);

    try {
      final response = await _client.get(uri).timeout(_timeout);
      return _handleResponse<T>(response, endpoint, parser);
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on FormatException {
      throw const ApiException('Invalid response format from server');
    }
  }

  /// Builds the URI with query parameters.
  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  /// Handles the HTTP response and parses the data.
  T _handleResponse<T>(
    http.Response response,
    String endpoint,
    T Function(dynamic data) parser,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = json.decode(response.body);

      // Handle wrapped response format { "data": [...] }
      if (jsonData is Map && jsonData.containsKey('data')) {
        return parser(jsonData['data']);
      }

      return parser(jsonData);
    }

    throw ApiException(
      _getErrorMessage(response.statusCode),
      statusCode: response.statusCode,
      endpoint: endpoint,
    );
  }

  /// Returns a user-friendly error message based on status code.
  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please try again.';
      case 401:
        return 'Authentication required. Please log in.';
      case 403:
        return 'Access denied. You don\'t have permission.';
      case 404:
        return 'Data not found.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Server is temporarily unavailable.';
      case 503:
        return 'Service is under maintenance.';
      default:
        return 'An unexpected error occurred (Code: $statusCode)';
    }
  }

  /// Disposes of the HTTP client resources.
  void dispose() {
    _client.close();
  }
}
