import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class PortfolioProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _holdings = [];
  Map<String, dynamic>? _performance;
  bool _isLoading = false;
  String? _error;
  String _selectedTimeframe = '7d';

  Map<String, dynamic>? get summary => _summary;
  List<Map<String, dynamic>> get holdings => _holdings;
  Map<String, dynamic>? get performance => _performance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedTimeframe => _selectedTimeframe;

  bool get hasData => _summary != null || _holdings.isNotEmpty;
  bool get hasError => _error != null;

  double get totalValue {
    if (_summary == null) return 0.0;
    return _parseDouble(_summary!['totalValue']);
  }

  double get totalProfitLoss {
    if (_summary == null) return 0.0;
    return _parseDouble(_summary!['totalPnl']);
  }

  double get totalProfitLossPercent {
    if (_summary == null) return 0.0;
    return _parseDouble(_summary!['totalPnlPercent']);
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

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
      _summary = await _apiService.getPortfolio();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadHoldings() async {
    try {
      _holdings = await _apiService.getPortfolioHoldings();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPerformance(String timeframe) async {
    _selectedTimeframe = timeframe;
    try {
      _performance = await _apiService.getPortfolioPerformance(
        timeframe: timeframe,
      );
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
