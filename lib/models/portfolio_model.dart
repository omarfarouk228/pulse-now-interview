import 'package:flutter/foundation.dart';

/// Model representing a portfolio summary.
@immutable
class PortfolioSummary {
  final double totalValue;
  final double totalPnl;
  final double totalPnlPercent;
  final int totalHoldings;
  final DateTime? lastUpdated;

  const PortfolioSummary({
    required this.totalValue,
    required this.totalPnl,
    required this.totalPnlPercent,
    this.totalHoldings = 0,
    this.lastUpdated,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalValue: _parseDouble(json['totalValue']),
      totalPnl: _parseDouble(json['totalPnl']),
      totalPnlPercent: _parseDouble(json['totalPnlPercent']),
      totalHoldings: _parseInt(json['totalHoldings']),
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
      'totalHoldings': totalHoldings,
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
  final double quantity;
  final double averagePrice;
  final double currentPrice;
  final double value;
  final double pnl;
  final double pnlPercent;
  final double allocation;
  final DateTime? lastUpdated;

  const PortfolioHolding({
    required this.id,
    required this.symbol,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.value,
    required this.pnl,
    required this.pnlPercent,
    this.allocation = 0.0,
    this.lastUpdated,
  });

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      id: json['id'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      quantity: _parseDouble(json['quantity']),
      averagePrice: _parseDouble(json['averagePrice']),
      currentPrice: _parseDouble(json['currentPrice']),
      value: _parseDouble(json['value']),
      pnl: _parseDouble(json['pnl']),
      pnlPercent: _parseDouble(json['pnlPercent']),
      allocation: _parseDouble(json['allocation']),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'currentPrice': currentPrice,
      'value': value,
      'pnl': pnl,
      'pnlPercent': pnlPercent,
      'allocation': allocation,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
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
  final List<PerformanceDataPoint> dataPoints;
  final PerformanceSummary summary;

  const PortfolioPerformance({
    required this.timeframe,
    this.dataPoints = const [],
    this.summary = const PerformanceSummary(),
  });

  factory PortfolioPerformance.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];

    return PortfolioPerformance(
      timeframe: json['timeframe'] as String? ?? '',
      dataPoints: dataList
          .map((e) => PerformanceDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] != null
          ? PerformanceSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : const PerformanceSummary(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeframe': timeframe,
      'data': dataPoints.map((e) => e.toJson()).toList(),
      'summary': summary.toJson(),
    };
  }

  bool get isPositive => summary.totalReturn >= 0;
  bool get hasData => dataPoints.isNotEmpty;

  // Convenience getters
  double get startValue => summary.startValue;
  double get endValue => summary.endValue;
  double get totalReturn => summary.totalReturn;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortfolioPerformance && other.timeframe == timeframe;
  }

  @override
  int get hashCode => timeframe.hashCode;
}

/// Model representing a single data point in performance history.
@immutable
class PerformanceDataPoint {
  final DateTime timestamp;
  final double value;
  final double pnl;
  final double pnlPercent;

  const PerformanceDataPoint({
    required this.timestamp,
    required this.value,
    this.pnl = 0.0,
    this.pnlPercent = 0.0,
  });

  factory PerformanceDataPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceDataPoint(
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      value: _parseDouble(json['value']),
      pnl: _parseDouble(json['pnl']),
      pnlPercent: _parseDouble(json['pnlPercent']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'pnl': pnl,
      'pnlPercent': pnlPercent,
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
}

/// Model representing performance summary statistics.
@immutable
class PerformanceSummary {
  final double startValue;
  final double endValue;
  final double totalReturn;

  const PerformanceSummary({
    this.startValue = 0.0,
    this.endValue = 0.0,
    this.totalReturn = 0.0,
  });

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      startValue: _parseDouble(json['startValue']),
      endValue: _parseDouble(json['endValue']),
      totalReturn: _parseDouble(json['totalReturn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startValue': startValue,
      'endValue': endValue,
      'totalReturn': totalReturn,
    };
  }

  bool get isPositive => totalReturn >= 0;

  double get absoluteChange => endValue - startValue;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
