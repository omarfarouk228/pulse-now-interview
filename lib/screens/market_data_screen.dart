import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulsenow_flutter/themes/app_theme.dart';
import '../providers/market_data_provider.dart';
import '../models/market_data_model.dart';
import '../router/app_router.dart';
import '../utils/constants.dart';

class MarketDataScreen extends StatefulWidget {
  const MarketDataScreen({super.key});

  @override
  State<MarketDataScreen> createState() => _MarketDataScreenState();
}

class _MarketDataScreenState extends State<MarketDataScreen> {
  @override
  void initState() {
    super.initState();
    // Load market data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketDataProvider>().loadMarketData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SortIndicator(),
        Expanded(
          child: Consumer<MarketDataProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && !provider.hasData) {
                return const _LoadingView();
              }

              if (provider.hasError && !provider.hasData) {
                return _ErrorView(
                  error: provider.error!,
                  onRetry: () => provider.loadMarketData(),
                );
              }

              if (!provider.hasData) {
                return _EmptyView(onRefresh: () => provider.loadMarketData());
              }

              return _MarketDataListView(
                marketData: provider.marketData,
                isLoading: provider.isLoading,
                onRefresh: () => provider.refreshMarketData(),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Loading indicator view.
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
            'Loading market data...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Error view with retry button.
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
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
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

/// Empty state view when no data is available.
class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Market Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh or tap the button below',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Data'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main list view for displaying market data.
class _MarketDataListView extends StatelessWidget {
  final List<MarketData> marketData;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _MarketDataListView({
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

/// Individual list item for market data.
class _MarketDataListItem extends StatelessWidget {
  final MarketData data;
  final VoidCallback? onTap;

  const _MarketDataListItem({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPositive = data.isPositiveChange;
    final changeColor = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return ListTile(
      onTap: onTap,
      leading: _CryptoIcon(symbol: data.baseCurrency),
      title: Text(
        data.symbol,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        _formatVolume(data.volume),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatPrice(data.price),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.15),
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

/// Simple icon widget for crypto symbols.
class _CryptoIcon extends StatelessWidget {
  final String symbol;

  const _CryptoIcon({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getColorForSymbol(symbol),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Color _getColorForSymbol(String symbol) {
    // Generate a consistent color based on the symbol
    final hash = symbol.hashCode;
    final colors = AppTheme.symbolColors;
    return colors[hash.abs() % colors.length];
  }
}

class _SortIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MarketDataProvider>(
      builder: (context, provider, child) {
        if (provider.sortOption == MarketDataSortOption.symbol &&
            provider.searchQuery.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              if (provider.searchQuery.isNotEmpty) ...[
                const Icon(Icons.search, size: 16),
                const SizedBox(width: 4),
                Text(
                  '"${provider.searchQuery}"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${provider.marketData.length} results)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
              if (provider.searchQuery.isNotEmpty &&
                  provider.sortOption != MarketDataSortOption.symbol)
                const Text(' | '),
              if (provider.sortOption != MarketDataSortOption.symbol) ...[
                const Icon(Icons.sort, size: 16),
                const SizedBox(width: 4),
                Text(_getSortLabel(provider.sortOption)),
              ],
              const Spacer(),
              if (provider.searchQuery.isNotEmpty ||
                  provider.sortOption != MarketDataSortOption.symbol)
                GestureDetector(
                  onTap: () {
                    provider.clearSearch();
                    provider.setSortOption(MarketDataSortOption.symbol);
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getSortLabel(MarketDataSortOption option) {
    switch (option) {
      case MarketDataSortOption.symbol:
        return 'Symbol';
      case MarketDataSortOption.priceAsc:
        return 'Price (Low)';
      case MarketDataSortOption.priceDesc:
        return 'Price (High)';
      case MarketDataSortOption.changeAsc:
        return 'Change (Worst)';
      case MarketDataSortOption.changeDesc:
        return 'Change (Best)';
      case MarketDataSortOption.volumeDesc:
        return 'Volume';
    }
  }
}
