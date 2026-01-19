import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulsenow_flutter/widgets/market_data/sort_indicator.dart';
import '../providers/market_data_provider.dart';
import '../widgets/common/empty_view.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/loading_view.dart';
import '../widgets/market_data/market_data_list_view.dart';

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
        const SortIndicator(),
        Expanded(
          child: Consumer<MarketDataProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && !provider.hasData) {
                return const LoadingView(message: 'Loading market data...');
              }

              if (provider.hasError && !provider.hasData) {
                return ErrorView(
                  error: provider.error!,
                  onRetry: () => provider.loadMarketData(),
                );
              }

              if (!provider.hasData) {
                return EmptyView(
                  title: 'No Market Data',
                  message: 'Pull down to refresh or tap the button below',
                  onRefresh: () => provider.loadMarketData(),
                  icon: Icons.show_chart,
                );
              }

              return MarketDataListView(
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
