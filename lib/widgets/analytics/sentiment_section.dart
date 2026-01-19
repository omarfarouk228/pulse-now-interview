import 'package:flutter/material.dart';
import '../../models/analytics_model.dart';
import '../../utils/constants.dart';

class SentimentSection extends StatelessWidget {
  final MarketSentiment sentiment;

  const SentimentSection({super.key, required this.sentiment});

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
            color: changeColor.withAlpha((255 * 0.15).round()),
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
