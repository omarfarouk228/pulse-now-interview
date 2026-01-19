import 'package:flutter/foundation.dart';

/// Model representing the analytics overview.
@immutable
class AnalyticsOverview {
  final double totalMarketCap;
  final double totalVolume24h;
  final int activeMarkets;
  final MarketLeader? topGainer;
  final MarketLeader? topLoser;
  final MarketDominance dominance;
  final DateTime? lastUpdated;

  const AnalyticsOverview({
    required this.totalMarketCap,
    required this.totalVolume24h,
    this.activeMarkets = 0,
    this.topGainer,
    this.topLoser,
    this.dominance = const MarketDominance(),
    this.lastUpdated,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      totalMarketCap: _parseDouble(json['totalMarketCap']),
      totalVolume24h: _parseDouble(json['totalVolume24h']),
      activeMarkets: _parseInt(json['activeMarkets']),
      topGainer: json['topGainer'] != null
          ? MarketLeader.fromJson(json['topGainer'] as Map<String, dynamic>)
          : null,
      topLoser: json['topLoser'] != null
          ? MarketLeader.fromJson(json['topLoser'] as Map<String, dynamic>)
          : null,
      dominance: json['marketDominance'] != null
          ? MarketDominance.fromJson(
              json['marketDominance'] as Map<String, dynamic>,
            )
          : const MarketDominance(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMarketCap': totalMarketCap,
      'totalVolume24h': totalVolume24h,
      'activeMarkets': activeMarkets,
      if (topGainer != null) 'topGainer': topGainer!.toJson(),
      if (topLoser != null) 'topLoser': topLoser!.toJson(),
      'marketDominance': dominance.toJson(),
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  double get btcDominance => dominance.btc;
  double get ethDominance => dominance.eth;

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
    return other is AnalyticsOverview &&
        other.totalMarketCap == totalMarketCap &&
        other.totalVolume24h == totalVolume24h;
  }

  @override
  int get hashCode => Object.hash(totalMarketCap, totalVolume24h);
}

/// Model representing market dominance percentages.
@immutable
class MarketDominance {
  final double btc;
  final double eth;
  final double others;

  const MarketDominance({this.btc = 0.0, this.eth = 0.0, this.others = 0.0});

  factory MarketDominance.fromJson(Map<String, dynamic> json) {
    return MarketDominance(
      btc: _parseDouble(json['btc']),
      eth: _parseDouble(json['eth']),
      others: _parseDouble(json['others']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'btc': btc, 'eth': eth, 'others': others};
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model representing a market leader (top gainer or loser).
@immutable
class MarketLeader {
  final String symbol;
  final double price;
  final double change;

  const MarketLeader({
    required this.symbol,
    required this.price,
    required this.change,
  });

  factory MarketLeader.fromJson(Map<String, dynamic> json) {
    return MarketLeader(
      symbol: json['symbol'] as String? ?? '',
      price: _parseDouble(json['price']),
      change: _parseDouble(json['change']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'symbol': symbol, 'price': price, 'change': change};
  }

  bool get isPositive => change >= 0;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model representing market trends (time series data for charts).
@immutable
class MarketTrends {
  final String timeframe;
  final List<TrendDataPoint> dataPoints;
  final TrendSummary summary;

  const MarketTrends({
    required this.timeframe,
    this.dataPoints = const [],
    this.summary = const TrendSummary(),
  });

  factory MarketTrends.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];

    return MarketTrends(
      timeframe: json['timeframe'] as String? ?? '',
      dataPoints: dataList
          .map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] != null
          ? TrendSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : const TrendSummary(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeframe': timeframe,
      'data': dataPoints.map((e) => e.toJson()).toList(),
      'summary': summary.toJson(),
    };
  }

  bool get isPositiveTrend => summary.change >= 0;
  bool get hasData => dataPoints.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketTrends && other.timeframe == timeframe;
  }

  @override
  int get hashCode => timeframe.hashCode;
}

/// Model representing a single data point in the trends time series.
@immutable
class TrendDataPoint {
  final DateTime timestamp;
  final double marketCap;
  final double volume;
  final double priceIndex;

  const TrendDataPoint({
    required this.timestamp,
    required this.marketCap,
    required this.volume,
    required this.priceIndex,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      marketCap: _parseDouble(json['marketCap']),
      volume: _parseDouble(json['volume']),
      priceIndex: _parseDouble(json['priceIndex']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'marketCap': marketCap,
      'volume': volume,
      'priceIndex': priceIndex,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model representing the trend summary statistics.
@immutable
class TrendSummary {
  final double change;
  final double volatility;

  const TrendSummary({this.change = 0.0, this.volatility = 0.0});

  factory TrendSummary.fromJson(Map<String, dynamic> json) {
    return TrendSummary(
      change: _parseDouble(json['change']),
      volatility: _parseDouble(json['volatility']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'change': change, 'volatility': volatility};
  }

  bool get isPositive => change >= 0;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model representing market sentiment data.
@immutable
class MarketSentiment {
  final SentimentOverall overall;
  final SentimentIndicators indicators;
  final List<SentimentBreakdown> breakdown;
  final DateTime? lastUpdated;

  const MarketSentiment({
    this.overall = const SentimentOverall(),
    this.indicators = const SentimentIndicators(),
    this.breakdown = const [],
    this.lastUpdated,
  });

  factory MarketSentiment.fromJson(Map<String, dynamic> json) {
    final breakdownList = json['breakdown'] as List<dynamic>? ?? [];

    return MarketSentiment(
      overall: json['overall'] != null
          ? SentimentOverall.fromJson(json['overall'] as Map<String, dynamic>)
          : const SentimentOverall(),
      indicators: json['indicators'] != null
          ? SentimentIndicators.fromJson(
              json['indicators'] as Map<String, dynamic>,
            )
          : const SentimentIndicators(),
      breakdown: breakdownList
          .map((e) => SentimentBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall.toJson(),
      'indicators': indicators.toJson(),
      'breakdown': breakdown.map((e) => e.toJson()).toList(),
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  // Convenience getters
  double get score => overall.score;
  String get label => overall.label;
  double get fearGreedIndex => indicators.fearGreedIndex;
  bool get isBullish => overall.label.toLowerCase() == 'bullish';
  bool get isBearish => overall.label.toLowerCase() == 'bearish';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketSentiment && other.overall == overall;
  }

  @override
  int get hashCode => overall.hashCode;
}

/// Model representing the overall sentiment score.
@immutable
class SentimentOverall {
  final double score;
  final String label;
  final double change24h;

  const SentimentOverall({
    this.score = 0.0,
    this.label = 'Neutral',
    this.change24h = 0.0,
  });

  factory SentimentOverall.fromJson(Map<String, dynamic> json) {
    return SentimentOverall(
      score: _parseDouble(json['score']),
      label: json['label'] as String? ?? 'Neutral',
      change24h: _parseDouble(json['change24h']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'score': score, 'label': label, 'change24h': change24h};
  }

  bool get isPositiveChange => change24h >= 0;

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
    return other is SentimentOverall &&
        other.score == score &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(score, label);
}

/// Model representing sentiment indicators.
@immutable
class SentimentIndicators {
  final double fearGreedIndex;
  final double socialSentiment;
  final double technicalAnalysis;
  final double onChainMetrics;

  const SentimentIndicators({
    this.fearGreedIndex = 0.0,
    this.socialSentiment = 0.0,
    this.technicalAnalysis = 0.0,
    this.onChainMetrics = 0.0,
  });

  factory SentimentIndicators.fromJson(Map<String, dynamic> json) {
    return SentimentIndicators(
      fearGreedIndex: _parseDouble(json['fearGreedIndex']),
      socialSentiment: _parseDouble(json['socialSentiment']),
      technicalAnalysis: _parseDouble(json['technicalAnalysis']),
      onChainMetrics: _parseDouble(json['onChainMetrics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fearGreedIndex': fearGreedIndex,
      'socialSentiment': socialSentiment,
      'technicalAnalysis': technicalAnalysis,
      'onChainMetrics': onChainMetrics,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model representing a sentiment breakdown item.
@immutable
class SentimentBreakdown {
  final String category;
  final double score;
  final double weight;

  const SentimentBreakdown({
    required this.category,
    required this.score,
    required this.weight,
  });

  factory SentimentBreakdown.fromJson(Map<String, dynamic> json) {
    return SentimentBreakdown(
      category: json['category'] as String? ?? '',
      score: _parseDouble(json['score']),
      weight: _parseDouble(json['weight']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'category': category, 'score': score, 'weight': weight};
  }

  double get weightedScore => score * weight;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
