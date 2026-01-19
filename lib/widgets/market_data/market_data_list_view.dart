import 'package:flutter/material.dart';
import '../../models/market_data_model.dart';
import '../../router/app_router.dart';
import '../../utils/constants.dart';
import '../common/crypto_icon.dart';

class MarketDataListView extends StatelessWidget {
  final List<MarketData> marketData;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const MarketDataListView({
    super.key,
    required this.marketData,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: marketData.length,
        itemBuilder: (context, index) {
          final data = marketData[index];
          return _MarketDataListItem(
            data: data,
            onTap: () => _navigateToDetail(context, data),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, MarketData data) {
    AppRouter.goToMarketDetail(data);
  }
}

class _MarketDataListItem extends StatelessWidget {
  final MarketData data;
  final VoidCallback? onTap;

  const _MarketDataListItem({
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = data.isPositiveChange;
    final changeColor = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return ListTile(
      onTap: onTap,
      leading: CryptoIcon(symbol: data.baseCurrency, radius: 22),
      title: Text(
        data.symbol,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        _formatVolume(data.volume),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatPrice(data.price),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: changeColor.withAlpha((255 * 0.15).round()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatPercentage(data.changePercent24h),
              style: TextStyle(
                color: changeColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${price.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )}';
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

  String _formatVolume(double volume) {
    if (volume >= 1e9) {
      return 'Vol: \$${(volume / 1e9).toStringAsFixed(2)}B';
    } else if (volume >= 1e6) {
      return 'Vol: \$${(volume / 1e6).toStringAsFixed(2)}M';
    } else if (volume >= 1e3) {
      return 'Vol: \$${(volume / 1e3).toStringAsFixed(2)}K';
    }
    return 'Vol: \$${volume.toStringAsFixed(2)}';
  }
}

