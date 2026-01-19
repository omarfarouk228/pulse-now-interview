import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulsenow_flutter/themes/app_theme.dart';
import '../providers/portfolio_provider.dart';
import '../utils/constants.dart';

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
          return const _LoadingView();
        }

        if (provider.hasError && !provider.hasData) {
          return _ErrorView(
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
                _PortfolioSummaryCard(provider: provider),
                const SizedBox(height: 24),
                _TimeframeSelector(
                  selected: provider.selectedTimeframe,
                  onChanged: (timeframe) => provider.setTimeframe(timeframe),
                ),
                const SizedBox(height: 16),
                if (provider.performance != null)
                  _PerformanceSection(performance: provider.performance!),
                const SizedBox(height: 24),
                _HoldingsSection(holdings: provider.holdings),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
            'Loading portfolio...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

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
              'Failed to load portfolio',
              style: Theme.of(context).textTheme.titleLarge,
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

class _PortfolioSummaryCard extends StatelessWidget {
  final PortfolioProvider provider;

  const _PortfolioSummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isPositive = provider.totalProfitLoss >= 0;
    final changeColor = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Portfolio Value',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(provider.totalValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatCurrency(provider.totalProfitLoss.abs())} (${isPositive ? '+' : ''}${provider.totalProfitLossPercent.toStringAsFixed(2)}%)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return '\$${value.toStringAsFixed(2)}';
  }
}

class _TimeframeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TimeframeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final timeframes = ['7d', '30d', '90d', '1y'];

    return Row(
      children: timeframes.map((tf) {
        final isSelected = tf == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(tf),
            selected: isSelected,
            onSelected: (_) => onChanged(tf),
          ),
        );
      }).toList(),
    );
  }
}

class _PerformanceSection extends StatelessWidget {
  final Map<String, dynamic> performance;

  const _PerformanceSection({required this.performance});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PerformanceCard(
                title: 'Return',
                value:
                    '${(performance['return'] as num?)?.toStringAsFixed(2) ?? '0.00'}%',
                isPositive: ((performance['return'] as num?) ?? 0) >= 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PerformanceCard(
                title: 'Best Day',
                value:
                    '${(performance['bestDay'] as num?)?.toStringAsFixed(2) ?? '0.00'}%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PerformanceCard(
                title: 'Worst Day',
                value:
                    '${(performance['worstDay'] as num?)?.toStringAsFixed(2) ?? '0.00'}%',
                isPositive: false,
              ),
            ),
          ],
        ),
      ],
    );
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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

class _HoldingsSection extends StatelessWidget {
  final List<Map<String, dynamic>> holdings;

  const _HoldingsSection({required this.holdings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Holdings',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${holdings.length} assets',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (holdings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('No holdings yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          ...holdings.map((holding) => _HoldingItem(holding: holding)),
      ],
    );
  }
}

class _HoldingItem extends StatelessWidget {
  final Map<String, dynamic> holding;

  const _HoldingItem({required this.holding});

  @override
  Widget build(BuildContext context) {
    final symbol = holding['symbol'] ?? '';
    final amount = (holding['amount'] as num?)?.toDouble() ?? 0.0;
    final value = (holding['value'] as num?)?.toDouble() ?? 0.0;
    final profitLoss = (holding['profitLoss'] as num?)?.toDouble() ?? 0.0;
    final profitLossPercent =
        (holding['profitLossPercent'] as num?)?.toDouble() ?? 0.0;
    final isPositive = profitLoss >= 0;
    final changeColor = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _CryptoIcon(symbol: symbol),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(6)} units',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    final hash = symbol.hashCode;
    final colors = AppTheme.symbolColors;
    return colors[hash.abs() % colors.length];
  }
}
