import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/market_data_provider.dart';
import 'market_data_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _SearchField(
                controller: _searchController,
                onChanged: (value) {
                  context.read<MarketDataProvider>().setSearchQuery(value);
                },
              )
            : const Text('PulseNow'),
        elevation: 0,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              tooltip: 'Search',
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  context.read<MarketDataProvider>().clearSearch();
                });
              },
              tooltip: 'Close search',
            ),
          _SortMenuButton(),
        ],
      ),
      body: Column(
        children: [
          _SortIndicator(),
          const Expanded(child: MarketDataScreen()),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search symbols...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(fontSize: 18),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MarketDataSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort by',
      onSelected: (option) {
        context.read<MarketDataProvider>().setSortOption(option);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: MarketDataSortOption.symbol,
          child: _SortMenuItem(
            icon: Icons.sort_by_alpha,
            label: 'Symbol (A-Z)',
          ),
        ),
        const PopupMenuItem(
          value: MarketDataSortOption.priceDesc,
          child: _SortMenuItem(
            icon: Icons.arrow_downward,
            label: 'Price (High to Low)',
          ),
        ),
        const PopupMenuItem(
          value: MarketDataSortOption.priceAsc,
          child: _SortMenuItem(
            icon: Icons.arrow_upward,
            label: 'Price (Low to High)',
          ),
        ),
        const PopupMenuItem(
          value: MarketDataSortOption.changeDesc,
          child: _SortMenuItem(icon: Icons.trending_up, label: 'Change (Best)'),
        ),
        const PopupMenuItem(
          value: MarketDataSortOption.changeAsc,
          child: _SortMenuItem(
            icon: Icons.trending_down,
            label: 'Change (Worst)',
          ),
        ),
        const PopupMenuItem(
          value: MarketDataSortOption.volumeDesc,
          child: _SortMenuItem(
            icon: Icons.bar_chart,
            label: 'Volume (Highest)',
          ),
        ),
      ],
    );
  }
}

class _SortMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SortMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
    );
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
