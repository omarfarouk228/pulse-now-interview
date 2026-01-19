import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/analytics_model.dart';
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
  final AnalyticsOverview overview;

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
              value: _formatLargeNumber(overview.totalMarketCap),
              icon: Icons.pie_chart,
              color: Colors.blue,
            ),
            _StatCard(
              title: '24h Volume',
              value: _formatLargeNumber(overview.totalVolume24h),
              icon: Icons.bar_chart,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Active Markets',
              value: '${overview.activeMarkets}',
              icon: Icons.show_chart,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'BTC Dominance',
              value: '${overview.btcDominance.toStringAsFixed(1)}%',
              icon: Icons.currency_bitcoin,
              color: Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  String _formatLargeNumber(double value) {
    if (value >= 1e12) return '\$${(value / 1e12).toStringAsFixed(2)}T';
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(2)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(2)}M';
    return '\$${value.toStringAsFixed(2)}';
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
  final MarketTrends trends;

  const _TrendsSection({required this.trends});

  @override
  Widget build(BuildContext context) {
    final isPositive = trends.isPositiveTrend;
    final changeColor = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TrendStat(
                    label: 'Change (${trends.timeframe})',
                    value:
                        '${isPositive ? '+' : ''}${trends.summary.change.toStringAsFixed(2)}%',
                    color: changeColor,
                    icon: isPositive ? Icons.trending_up : Icons.trending_down,
                  ),
                  _TrendStat(
                    label: 'Volatility',
                    value: '${trends.summary.volatility.toStringAsFixed(2)}%',
                    color: Colors.orange,
                    icon: Icons.show_chart,
                  ),
                ],
              ),
              if (trends.hasData) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _MiniChart(dataPoints: trends.dataPoints),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TrendStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniChart extends StatelessWidget {
  final List<TrendDataPoint> dataPoints;

  const _MiniChart({required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) return const SizedBox.shrink();

    final prices = dataPoints.map((e) => e.priceIndex).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final range = maxPrice - minPrice;

    final isPositive = prices.last >= prices.first;
    final lineColor = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return SizedBox(
      height: 80,
      child: CustomPaint(
        size: const Size(double.infinity, 80),
        painter: _ChartPainter(
          prices: prices,
          minPrice: minPrice,
          range: range == 0 ? 1 : range,
          lineColor: lineColor,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> prices;
  final double minPrice;
  final double range;
  final Color lineColor;

  _ChartPainter({
    required this.prices,
    required this.minPrice,
    required this.range,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < prices.length; i++) {
      final x = (i / (prices.length - 1)) * size.width;
      final y = size.height - ((prices[i] - minPrice) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SentimentSection extends StatelessWidget {
  final MarketSentiment sentiment;

  const _SentimentSection({required this.sentiment});

  @override
  Widget build(BuildContext context) {
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
              _OverallSentimentGauge(overall: sentiment.overall),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _IndicatorsSection(indicators: sentiment.indicators),
              if (sentiment.breakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _BreakdownSection(breakdown: sentiment.breakdown),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OverallSentimentGauge extends StatelessWidget {
  final SentimentOverall overall;

  const _OverallSentimentGauge({required this.overall});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForScore(overall.score);
    final changeColor = overall.isPositiveChange
        ? const Color(AppConstants.positiveColor)
        : const Color(AppConstants.negativeColor);

    return Column(
      children: [
        Text(
          'Overall Sentiment',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: overall.score / 100,
                strokeWidth: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(
              children: [
                Text(
                  overall.score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  overall.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: changeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${overall.isPositiveChange ? '+' : ''}${overall.change24h.toStringAsFixed(0)} (24h)',
            style: TextStyle(
              color: changeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForScore(double score) {
    if (score <= 25) return Colors.red;
    if (score <= 45) return Colors.orange;
    if (score <= 55) return Colors.grey;
    if (score <= 75) return Colors.lightGreen;
    return Colors.green;
  }
}

class _IndicatorsSection extends StatelessWidget {
  final SentimentIndicators indicators;

  const _IndicatorsSection({required this.indicators});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicators',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        _IndicatorBar(
          label: 'Fear & Greed',
          value: indicators.fearGreedIndex,
          color: _getColorForValue(indicators.fearGreedIndex),
        ),
        const SizedBox(height: 8),
        _IndicatorBar(
          label: 'Social',
          value: indicators.socialSentiment,
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        _IndicatorBar(
          label: 'Technical',
          value: indicators.technicalAnalysis,
          color: Colors.purple,
        ),
        const SizedBox(height: 8),
        _IndicatorBar(
          label: 'On-Chain',
          value: indicators.onChainMetrics,
          color: Colors.teal,
        ),
      ],
    );
  }

  Color _getColorForValue(double value) {
    if (value <= 25) return Colors.red;
    if (value <= 45) return Colors.orange;
    if (value <= 55) return Colors.grey;
    if (value <= 75) return Colors.lightGreen;
    return Colors.green;
  }
}

class _IndicatorBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _IndicatorBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  final List<SentimentBreakdown> breakdown;

  const _BreakdownSection({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breakdown',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        ...breakdown.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _BreakdownItem(item: item),
          ),
        ),
      ],
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final SentimentBreakdown item;

  const _BreakdownItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForScore(item.score);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(item.category, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            item.score.toStringAsFixed(0),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 35,
          child: Text(
            '(${(item.weight * 100).toStringAsFixed(0)}%)',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Color _getColorForScore(double score) {
    if (score <= 25) return Colors.red;
    if (score <= 45) return Colors.orange;
    if (score <= 55) return Colors.grey;
    if (score <= 75) return Colors.lightGreen;
    return Colors.green;
  }
}
