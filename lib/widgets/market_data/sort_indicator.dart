import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/market_data_provider.dart';

class SortIndicator extends StatelessWidget {
  const SortIndicator({super.key});

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
                      color: Colors.blue,
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
