import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulsenow_flutter/themes/app_theme.dart';
import '../models/market_data_model.dart';
import '../providers/market_data_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class MarketDetailScreen extends StatefulWidget {
  final MarketData marketData;

  const MarketDetailScreen({super.key, required this.marketData});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>>? _historyData;
  bool _isLoadingHistory = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final data = await _apiService.getMarketHistory(
        symbol: widget.marketData.symbol,
        timeframe: '1h',
        limit: 24,
      );
      setState(() {
        _historyData = data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _historyError = e.toString();
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for real-time updates
    final provider = context.watch<MarketDataProvider>();
    final currentData =
        provider.getBySymbol(widget.marketData.symbol) ?? widget.marketData;

    final isPositive = currentData.isPositiveChange;
    final changeColor = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return Scaffold(
      appBar: AppBar(title: Text(currentData.symbol), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.refreshMarketData();
          await _loadHistoryData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PriceHeader(marketData: currentData, changeColor: changeColor),
              const Divider(),
              _StatsSection(marketData: currentData),
              const Divider(),
              _HistorySection(
                historyData: _historyData,
                isLoading: _isLoadingHistory,
                error: _historyError,
                onRetry: _loadHistoryData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}

class _PriceHeader extends StatelessWidget {
  final MarketData marketData;
  final Color changeColor;

  const _PriceHeader({required this.marketData, required this.changeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CryptoLargeIcon(symbol: marketData.baseCurrency),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marketData.baseCurrency,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      marketData.symbol,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _formatPrice(marketData.price),
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      marketData.isPositiveChange
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: changeColor,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatPercentage(marketData.changePercent24h),
                      style: TextStyle(
                        color: changeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${marketData.isPositiveChange ? '+' : ''}\$${marketData.change24h.toStringAsFixed(2)}',
                style: TextStyle(color: changeColor, fontSize: 14),
              ),
              const Spacer(),
              const Text('24h', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${price.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } else if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${price.toStringAsFixed(6)}';
    }
  }

  String _formatPercentage(double percentage) {
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(2)}%';
  }
}

class _StatsSection extends StatelessWidget {
  final MarketData marketData;

  const _StatsSection({required this.marketData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '24h Volume',
                  value: _formatVolume(marketData.volume),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Market Cap',
                  value: marketData.marketCap != null
                      ? _formatVolume(marketData.marketCap!)
                      : 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '24h High',
                  value: marketData.high24h != null
                      ? '\$${marketData.high24h!.toStringAsFixed(2)}'
                      : 'N/A',
                  valueColor: const Color(AppConstants.positiveColor),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '24h Low',
                  value: marketData.low24h != null
                      ? '\$${marketData.low24h!.toStringAsFixed(2)}'
                      : 'N/A',
                  valueColor: const Color(AppConstants.negativeColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1e12) {
      return '\$${(volume / 1e12).toStringAsFixed(2)}T';
    } else if (volume >= 1e9) {
      return '\$${(volume / 1e9).toStringAsFixed(2)}B';
    } else if (volume >= 1e6) {
      return '\$${(volume / 1e6).toStringAsFixed(2)}M';
    } else if (volume >= 1e3) {
      return '\$${(volume / 1e3).toStringAsFixed(2)}K';
    }
    return '\$${volume.toStringAsFixed(2)}';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<Map<String, dynamic>>? historyData;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _HistorySection({
    required this.historyData,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price History (24h)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            Center(
              child: Column(
                children: [
                  const Text(
                    'Failed to load history',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            )
          else if (historyData != null && historyData!.isNotEmpty)
            _PriceHistoryChart(data: historyData!)
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No history data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceHistoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _PriceHistoryChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Simple text-based price history display
    // In a real app, you would use a charting library like fl_chart
    final prices = data
        .map((d) => (d['close'] as num?)?.toDouble() ?? 0.0)
        .toList();

    if (prices.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final isUpTrend = prices.last >= prices.first;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'High: \$${maxPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(AppConstants.positiveColor),
                ),
              ),
              Text(
                'Low: \$${minPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(AppConstants.negativeColor),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Simple visual indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUpTrend ? Icons.trending_up : Icons.trending_down,
                color: Color(
                  isUpTrend
                      ? AppConstants.positiveColor
                      : AppConstants.negativeColor,
                ),
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                isUpTrend ? 'Upward Trend' : 'Downward Trend',
                style: TextStyle(
                  color: Color(
                    isUpTrend
                        ? AppConstants.positiveColor
                        : AppConstants.negativeColor,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${prices.length} data points',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CryptoLargeIcon extends StatelessWidget {
  final String symbol;

  const _CryptoLargeIcon({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _getColorForSymbol(symbol),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Text(
          symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Color _getColorForSymbol(String symbol) {
    final hash = symbol.hashCode;
    final colors = AppTheme.symbolColors;
    return colors[hash.abs() % colors.length];
  }
}
