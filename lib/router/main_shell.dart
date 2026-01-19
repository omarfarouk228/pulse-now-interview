import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/market_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/market_data_screen.dart';
import '../../screens/analytics_screen.dart';
import '../../screens/portfolio_screen.dart';

/// Main shell widget with bottom navigation.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  final List<_NavDestination> _destinations = const [
    _NavDestination(
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      label: 'Markets',
    ),
    _NavDestination(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Analytics',
    ),
    _NavDestination(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Portfolio',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          MarketDataScreen(),
          AnalyticsScreen(),
          PortfolioScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            if (_isSearching) {
              _isSearching = false;
              _searchController.clear();
              context.read<MarketDataProvider>().clearSearch();
            }
          });
        },
        destinations: _destinations
            .map(
              (dest) => NavigationDestination(
                icon: Icon(dest.icon),
                selectedIcon: Icon(dest.selectedIcon),
                label: dest.label,
              ),
            )
            .toList(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: _buildTitle(),
      elevation: 0,
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle() {
    if (_currentIndex == 0 && _isSearching) {
      return TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<MarketDataProvider>().setSearchQuery(value);
        },
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search symbols...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
        ),
        style: const TextStyle(fontSize: 18),
      );
    }

    return Text(_getTitle());
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Markets';
      case 1:
        return 'Analytics';
      case 2:
        return 'Portfolio';
      default:
        return 'PulseNow';
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      // Search button (only for Markets tab)
      if (_currentIndex == 0 && !_isSearching)
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
          tooltip: 'Search',
        ),
      // Close search button
      if (_currentIndex == 0 && _isSearching)
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
      // Theme toggle button
      Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          );
        },
      ),
      // Sort button (only for Markets tab)
      if (_currentIndex == 0) _SortMenuButton(),
    ];
  }
}

class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
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
