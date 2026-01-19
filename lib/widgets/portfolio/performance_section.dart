import 'package:flutter/material.dart';
import '../../models/portfolio_model.dart';
import '../../utils/constants.dart';
import '../common/area_chart.dart';

class PerformanceSection extends StatelessWidget {
  final PortfolioPerformance performance;

  const PerformanceSection({super.key, required this.performance});

  @override
  Widget build(BuildContext context) {
    final isPositive = performance.isPositive;
    final changeColor = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance (${performance.timeframe})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                children: [
                  Expanded(
                    child: _PerformanceCard(
                      title: 'Return',
                      value: '${isPositive ? '+' : ''}${performance.totalReturn.toStringAsFixed(2)}%',
                      isPositive: isPositive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PerformanceCard(
                      title: 'Start',
                      value: _formatCurrency(performance.startValue),
                      isPositive: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PerformanceCard(
                      title: 'Current',
                      value: _formatCurrency(performance.endValue),
                      isPositive: isPositive,
                    ),
                  ),
                ],
              ),
              if (performance.hasData) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                AreaChart(
                  dataPoints: performance.dataPoints.map((e) => e.value).toList(),
                  lineColor: changeColor,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }
}

class _PerformanceCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isPositive;

  const _PerformanceCard({
    required this.title,
    required this.value,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

