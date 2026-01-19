import 'package:flutter/foundation.dart';
import '../models/analytics_model.dart';
import '../services/api_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  AnalyticsOverview? _overview;
  MarketTrends? _trends;
  MarketSentiment? _sentiment;
  bool _isLoading = false;
  String? _error;
  String _selectedTimeframe = '24h';

  AnalyticsOverview? get overview => _overview;
  MarketTrends? get trends => _trends;
  MarketSentiment? get sentiment => _sentiment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedTimeframe => _selectedTimeframe;

  bool get hasData =>
      _overview != null || _trends != null || _sentiment != null;
  bool get hasError => _error != null;

  Future<void> loadAllAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadOverview(),
        loadTrends(_selectedTimeframe),
        loadSentiment(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOverview() async {
    try {
      final data = await _apiService.getAnalyticsOverview();
      _overview = AnalyticsOverview.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTrends(String timeframe) async {
    _selectedTimeframe = timeframe;
    try {
      final data = await _apiService.getMarketTrends(timeframe: timeframe);
      _trends = MarketTrends.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSentiment() async {
    try {
      final data = await _apiService.getMarketSentiment();
      _sentiment = MarketSentiment.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setTimeframe(String timeframe) {
    if (_selectedTimeframe != timeframe) {
      loadTrends(timeframe);
    }
  }

  Future<void> refresh() async {
    await loadAllAnalytics();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
