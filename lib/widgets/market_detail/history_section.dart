import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class HistorySection extends StatelessWidget {
  final List<Map<String, dynamic>>? historyData;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const HistorySection({
    super.key,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
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
        color: Colors.grey.withAlpha((255 * 0.1).round()),
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
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
