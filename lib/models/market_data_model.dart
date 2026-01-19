import 'package:flutter/foundation.dart';

/// Model representing market data for a trading symbol.
///
/// Contains price information and 24-hour change metrics
/// for cryptocurrency trading pairs.
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

  const MarketData({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.volume,
    this.high24h,
    this.low24h,
    this.marketCap,
    this.lastUpdated,
  });

  /// Creates a MarketData instance from JSON response.
  ///
  /// Handles null safety by providing default values for optional fields.
  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      symbol: json['symbol'] as String? ?? '',
      price: _parseDouble(json['price']),
      change24h: _parseDouble(json['change24h']),
      changePercent24h: _parseDouble(json['changePercent24h']),
      volume: _parseDouble(json['volume']),
      high24h: json['high24h'] != null ? _parseDouble(json['high24h']) : null,
      low24h: json['low24h'] != null ? _parseDouble(json['low24h']) : null,
      marketCap: json['marketCap'] != null
          ? _parseDouble(json['marketCap'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }

  /// Safely parses a dynamic value to double.
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Converts the model to JSON format.
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price,
      'change24h': change24h,
      'changePercent24h': changePercent24h,
      'volume': volume,
      if (high24h != null) 'high24h': high24h,
      if (low24h != null) 'low24h': low24h,
      if (marketCap != null) 'marketCap': marketCap,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  /// Returns true if the 24h change is positive.
  bool get isPositiveChange => changePercent24h >= 0;

  /// Returns the base currency symbol (e.g., "BTC" from "BTC/USD").
  String get baseCurrency => symbol.split('/').first;

  /// Returns the quote currency symbol (e.g., "USD" from "BTC/USD").
  String get quoteCurrency {
    final parts = symbol.split('/');
    return parts.length > 1 ? parts[1] : 'USD';
  }

  /// Creates a copy of this MarketData with updated fields.
  MarketData copyWith({
    String? symbol,
    double? price,
    double? change24h,
    double? changePercent24h,
    double? volume,
    double? high24h,
    double? low24h,
    double? marketCap,
    DateTime? lastUpdated,
  }) {
    return MarketData(
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      changePercent24h: changePercent24h ?? this.changePercent24h,
      volume: volume ?? this.volume,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      marketCap: marketCap ?? this.marketCap,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketData &&
        other.symbol == symbol &&
        other.price == price &&
        other.change24h == change24h &&
        other.changePercent24h == changePercent24h &&
        other.volume == volume;
  }

  @override
  int get hashCode {
    return Object.hash(symbol, price, change24h, changePercent24h, volume);
  }

  @override
  String toString() {
    return 'MarketData(symbol: $symbol, price: $price, change24h: $changePercent24h%)';
  }
}
