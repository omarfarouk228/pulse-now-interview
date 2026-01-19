import 'package:flutter/foundation.dart';

/// Model representing a portfolio summary.
@immutable
class PortfolioSummary {
  final double totalValue;
  final double totalPnl;
  final double totalPnlPercent;
  final double totalInvested;
  final int holdingsCount;
  final DateTime? lastUpdated;

  const PortfolioSummary({
    required this.totalValue,
    required this.totalPnl,
    required this.totalPnlPercent,
    this.totalInvested = 0.0,
    this.holdingsCount = 0,
    this.lastUpdated,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalValue: _parseDouble(json['totalValue']),
      totalPnl: _parseDouble(json['totalPnl']),
      totalPnlPercent: _parseDouble(json['totalPnlPercent']),
      totalInvested: _parseDouble(json['totalInvested']),
      holdingsCount: _parseInt(json['holdingsCount']),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalValue': totalValue,
      'totalPnl': totalPnl,
      'totalPnlPercent': totalPnlPercent,
      'totalInvested': totalInvested,
      'holdingsCount': holdingsCount,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  bool get isProfitable => totalPnl >= 0;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortfolioSummary &&
        other.totalValue == totalValue &&
        other.totalPnl == totalPnl &&
        other.totalPnlPercent == totalPnlPercent;
  }

  @override
  int get hashCode => Object.hash(totalValue, totalPnl, totalPnlPercent);

  @override
  String toString() {
    return 'PortfolioSummary(totalValue: $totalValue, totalPnl: $totalPnl, totalPnlPercent: $totalPnlPercent%)';
  }
}

/// Model representing a single portfolio holding.
@immutable
class PortfolioHolding {
  final String id;
  final String symbol;
  final String name;
  final double quantity;
  final double averagePrice;
  final double currentPrice;
  final double value;
  final double pnl;
  final double pnlPercent;
  final double allocation;

  const PortfolioHolding({
    required this.id,
    required this.symbol,
    this.name = '',
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.value,
    required this.pnl,
    required this.pnlPercent,
    this.allocation = 0.0,
  });

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      id: json['id'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: _parseDouble(json['quantity']),
      averagePrice: _parseDouble(json['averagePrice']),
      currentPrice: _parseDouble(json['currentPrice']),
      value: _parseDouble(json['value']),
      pnl: _parseDouble(json['pnl']),
      pnlPercent: _parseDouble(json['pnlPercent']),
      allocation: _parseDouble(json['allocation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'currentPrice': currentPrice,
      'value': value,
      'pnl': pnl,
      'pnlPercent': pnlPercent,
      'allocation': allocation,
    };
  }

  bool get isProfitable => pnl >= 0;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortfolioHolding &&
        other.id == id &&
        other.symbol == symbol &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(id, symbol, quantity);

  @override
  String toString() {
    return 'PortfolioHolding(symbol: $symbol, quantity: $quantity, value: $value, pnl: $pnl)';
  }
}

/// Model representing portfolio performance over time.
@immutable
class PortfolioPerformance {
  final String timeframe;
  final double startValue;
  final double endValue;
  final double absoluteChange;
  final double percentChange;
  final double highValue;
  final double lowValue;
  final List<PerformanceDataPoint> dataPoints;

  const PortfolioPerformance({
    required this.timeframe,
    required this.startValue,
    required this.endValue,
    required this.absoluteChange,
    required this.percentChange,
    this.highValue = 0.0,
    this.lowValue = 0.0,
    this.dataPoints = const [],
  });

  factory PortfolioPerformance.fromJson(Map<String, dynamic> json) {
    final dataPointsList = json['dataPoints'] as List<dynamic>? ?? [];

    return PortfolioPerformance(
      timeframe: json['timeframe'] as String? ?? '',
      startValue: _parseDouble(json['startValue']),
      endValue: _parseDouble(json['endValue']),
      absoluteChange: _parseDouble(json['absoluteChange']),
      percentChange: _parseDouble(json['percentChange']),
      highValue: _parseDouble(json['highValue']),
      lowValue: _parseDouble(json['lowValue']),
      dataPoints: dataPointsList
          .map((e) => PerformanceDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeframe': timeframe,
      'startValue': startValue,
      'endValue': endValue,
      'absoluteChange': absoluteChange,
      'percentChange': percentChange,
      'highValue': highValue,
      'lowValue': lowValue,
      'dataPoints': dataPoints.map((e) => e.toJson()).toList(),
    };
  }

  bool get isPositive => percentChange >= 0;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortfolioPerformance &&
        other.timeframe == timeframe &&
        other.endValue == endValue;
  }

  @override
  int get hashCode => Object.hash(timeframe, endValue);
}

/// Model representing a single data point in performance history.
@immutable
class PerformanceDataPoint {
  final DateTime timestamp;
  final double value;

  const PerformanceDataPoint({required this.timestamp, required this.value});

  factory PerformanceDataPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceDataPoint(
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      value: _parseDouble(json['value']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'timestamp': timestamp.toIso8601String(), 'value': value};
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
