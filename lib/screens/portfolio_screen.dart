import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/loading_view.dart';
import '../widgets/common/timeframe_selector.dart';
import '../widgets/portfolio/holdings_section.dart';
import '../widgets/portfolio/performance_section.dart';
import '../widgets/portfolio/portfolio_summary_card.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioProvider>().loadAllPortfolioData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return const LoadingView(message: 'Loading portfolio...');
        }

        if (provider.hasError && !provider.hasData) {
          return ErrorView(
            title: 'Failed to load portfolio',
            error: provider.error!,
            onRetry: () => provider.loadAllPortfolioData(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PortfolioSummaryCard(provider: provider),
                const SizedBox(height: 24),
                TimeframeSelector(
                  selected: provider.selectedTimeframe,
                  onChanged: (timeframe) => provider.setTimeframe(timeframe),
                  timeframes: const ['7d', '30d', '90d', '1y'],
                ),
                const SizedBox(height: 16),
                if (provider.performance != null)
                  PerformanceSection(performance: provider.performance!),
                const SizedBox(height: 24),
                HoldingsSection(holdings: provider.holdings),
              ],
            ),
          ),
        );
      },
    );
  }
}
