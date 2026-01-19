import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/market_data_model.dart';
import '../providers/market_data_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/market_detail/history_section.dart';
import '../widgets/market_detail/price_header.dart';
import '../widgets/market_detail/stats_section.dart';

class MarketDetailScreen extends StatefulWidget {
  final MarketData marketData;

  const MarketDetailScreen({super.key, required this.marketData});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>>? _historyData;
  bool _isLoadingHistory = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final data = await _apiService.getMarketHistory(
        symbol: widget.marketData.symbol,
        timeframe: '1h',
        limit: 24,
      );
      setState(() {
        _historyData = data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _historyError = e.toString();
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for real-time updates
    final provider = context.watch<MarketDataProvider>();
    final currentData =
        provider.getBySymbol(widget.marketData.symbol) ?? widget.marketData;

    final isPositive = currentData.isPositiveChange;
    final changeColor = Color(
      isPositive ? AppConstants.positiveColor : AppConstants.negativeColor,
    );

    return Scaffold(
      appBar: AppBar(title: Text(currentData.symbol), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.refreshMarketData();
          await _loadHistoryData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PriceHeader(marketData: currentData, changeColor: changeColor),
              const Divider(),
              StatsSection(marketData: currentData),
              const Divider(),
              HistorySection(
                historyData: _historyData,
                isLoading: _isLoadingHistory,
                error: _historyError,
                onRetry: _loadHistoryData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
