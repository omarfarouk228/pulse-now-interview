import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics/overview_section.dart';
import '../widgets/analytics/sentiment_section.dart';
import '../widgets/analytics/trends_section.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/loading_view.dart';
import '../widgets/common/timeframe_selector.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAllAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return const LoadingView(message: 'Loading analytics...');
        }

        if (provider.hasError && !provider.hasData) {
          return ErrorView(
            title: 'Failed to load analytics',
            error: provider.error!,
            onRetry: () => provider.loadAllAnalytics(),
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
                if (provider.overview != null)
                  OverviewSection(overview: provider.overview!),
                const SizedBox(height: 24),
                TimeframeSelector(
                  selected: provider.selectedTimeframe,
                  onChanged: (timeframe) => provider.setTimeframe(timeframe),
                  timeframes: const ['24h', '7d', '30d'],
                ),
                const SizedBox(height: 16),
                if (provider.trends != null)
                  TrendsSection(trends: provider.trends!),
                const SizedBox(height: 24),
                if (provider.sentiment != null)
                  SentimentSection(sentiment: provider.sentiment!),
              ],
            ),
          ),
        );
      },
    );
  }
}
