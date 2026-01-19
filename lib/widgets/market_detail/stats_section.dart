import 'package:flutter/material.dart';
import '../../models/market_data_model.dart';
import '../../utils/constants.dart';

class StatsSection extends StatelessWidget {
  final MarketData marketData;

  const StatsSection({super.key, required this.marketData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
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
