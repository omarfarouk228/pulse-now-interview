import 'package:flutter/foundation.dart';
import '../models/portfolio_model.dart';
import '../services/api_service.dart';

class PortfolioProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  PortfolioSummary? _summary;
  List<PortfolioHolding> _holdings = [];
  PortfolioPerformance? _performance;
  bool _isLoading = false;
  String? _error;
  String _selectedTimeframe = '7d';

  PortfolioSummary? get summary => _summary;
  List<PortfolioHolding> get holdings => _holdings;
  PortfolioPerformance? get performance => _performance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedTimeframe => _selectedTimeframe;

  bool get hasData => _summary != null || _holdings.isNotEmpty;
  bool get hasError => _error != null;

  double get totalValue => _summary?.totalValue ?? 0.0;
  double get totalProfitLoss => _summary?.totalPnl ?? 0.0;
  double get totalProfitLossPercent => _summary?.totalPnlPercent ?? 0.0;

  Future<void> loadAllPortfolioData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadPortfolioSummary(),
        loadHoldings(),
        loadPerformance(_selectedTimeframe),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPortfolioSummary() async {
    try {
      final data = await _apiService.getPortfolio();
      _summary = PortfolioSummary.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadHoldings() async {
    try {
      final data = await _apiService.getPortfolioHoldings();
      _holdings = data.map((e) => PortfolioHolding.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPerformance(String timeframe) async {
    _selectedTimeframe = timeframe;
    try {
      final data = await _apiService.getPortfolioPerformance(
        timeframe: timeframe,
      );
      _performance = PortfolioPerformance.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setTimeframe(String timeframe) {
    if (_selectedTimeframe != timeframe) {
      loadPerformance(timeframe);
    }
  }

  Future<void> refresh() async {
    await loadAllPortfolioData();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
