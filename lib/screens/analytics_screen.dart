import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulsenow_flutter/themes/app_theme.dart';
import '../providers/analytics_provider.dart';
import '../utils/constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAllAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return const _LoadingView();
        }

        if (provider.hasError && !provider.hasData) {
          return _ErrorView(
            error: provider.error!,
            onRetry: () => provider.loadAllAnalytics(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.overview != null)
                  _OverviewSection(overview: provider.overview!),
                const SizedBox(height: 24),
                _TimeframeSelector(
                  selected: provider.selectedTimeframe,
                  onChanged: (timeframe) => provider.setTimeframe(timeframe),
                ),
                const SizedBox(height: 16),
                if (provider.trends != null)
                  _TrendsSection(trends: provider.trends!),
                const SizedBox(height: 24),
                if (provider.sentiment != null)
                  _SentimentSection(sentiment: provider.sentiment!),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading analytics...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final Map<String, dynamic> overview;

  const _OverviewSection({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: 'Total Market Cap',
              value: _formatLargeNumber(overview['totalMarketCap']),
              icon: Icons.pie_chart,
              color: AppTheme.primaryColor,
            ),
            _StatCard(
              title: '24h Volume',
              value: _formatLargeNumber(overview['totalVolume24h']),
              icon: Icons.bar_chart,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Active Markets',
              value: '${overview['activeMarkets'] ?? 0}',
              icon: Icons.show_chart,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'BTC Dominance',
              value: '${(overview['btcDominance'] ?? 0).toStringAsFixed(1)}%',
              icon: Icons.currency_bitcoin,
              color: Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  String _formatLargeNumber(dynamic value) {
    if (value == null) return '\$0';
    final number = (value as num).toDouble();
    if (number >= 1e12) return '\$${(number / 1e12).toStringAsFixed(2)}T';
    if (number >= 1e9) return '\$${(number / 1e9).toStringAsFixed(2)}B';
    if (number >= 1e6) return '\$${(number / 1e6).toStringAsFixed(2)}M';
    return '\$${number.toStringAsFixed(2)}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TimeframeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TimeframeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final timeframes = ['24h', '7d', '30d'];

    return Row(
      children: timeframes.map((tf) {
        final isSelected = tf == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(tf),
            selected: isSelected,
            onSelected: (_) => onChanged(tf),
          ),
        );
      }).toList(),
    );
  }
}

class _TrendsSection extends StatelessWidget {
  final Map<String, dynamic> trends;

  const _TrendsSection({required this.trends});

  @override
  Widget build(BuildContext context) {
    final gainers =
        (trends['topGainers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final losers =
        (trends['topLosers'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Trends',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (gainers.isNotEmpty) ...[
          _TrendList(title: 'Top Gainers', items: gainers, isPositive: true),
          const SizedBox(height: 16),
        ],
        if (losers.isNotEmpty)
          _TrendList(title: 'Top Losers', items: losers, isPositive: false),
      ],
    );
  }
}

class _TrendList extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final bool isPositive;

  const _TrendList({
    required this.title,
    required this.items,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.take(5).map((item) => _TrendItem(item: item, color: color)),
      ],
    );
  }
}

class _TrendItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color color;

  const _TrendItem({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final symbol = item['symbol'] ?? '';
    final change = (item['changePercent'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(symbol, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentimentSection extends StatelessWidget {
  final Map<String, dynamic> sentiment;

  const _SentimentSection({required this.sentiment});

  @override
  Widget build(BuildContext context) {
    final bullish = (sentiment['bullish'] as num?)?.toDouble() ?? 0.0;
    final bearish = (sentiment['bearish'] as num?)?.toDouble() ?? 0.0;
    final neutral = (sentiment['neutral'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Sentiment',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _SentimentBar(
                label: 'Bullish',
                value: bullish,
                color: const Color(AppConstants.positiveColor),
              ),
              const SizedBox(height: 12),
              _SentimentBar(
                label: 'Neutral',
                value: neutral,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              _SentimentBar(
                label: 'Bearish',
                value: bearish,
                color: const Color(AppConstants.negativeColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SentimentBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SentimentBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 45,
          child: Text(
            '${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
