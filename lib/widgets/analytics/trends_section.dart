import 'package:flutter/material.dart';
import '../../models/analytics_model.dart';
import '../../utils/constants.dart';
import '../common/area_chart.dart';

class TrendsSection extends StatelessWidget {
  final MarketTrends trends;

  const TrendsSection({super.key, required this.trends});

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
                AreaChart(
                  dataPoints: trends.dataPoints.map((e) => e.priceIndex).toList(),
                  lineColor: changeColor,
                ),
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

