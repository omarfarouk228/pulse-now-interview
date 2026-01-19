import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _trends;
  Map<String, dynamic>? _sentiment;
  bool _isLoading = false;
  String? _error;
  String _selectedTimeframe = '24h';

  Map<String, dynamic>? get overview => _overview;
  Map<String, dynamic>? get trends => _trends;
  Map<String, dynamic>? get sentiment => _sentiment;
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
      _overview = await _apiService.getAnalyticsOverview();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTrends(String timeframe) async {
    _selectedTimeframe = timeframe;
    try {
      _trends = await _apiService.getMarketTrends(timeframe: timeframe);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSentiment() async {
    try {
      _sentiment = await _apiService.getMarketSentiment();
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
