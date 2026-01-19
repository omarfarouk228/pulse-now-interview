import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/market_data_model.dart';

/// Enum representing the different sort options for market data.
enum MarketDataSortOption {
  symbol,
  priceAsc,
  priceDesc,
  changeAsc,
  changeDesc,
  volumeDesc,
}

/// Provider for managing market data state.
///
/// Handles data fetching, loading states, error handling,
/// and provides sorting/filtering capabilities.
class MarketDataProvider with ChangeNotifier {
  final ApiService _apiService;

  List<MarketData> _marketData = [];
  List<MarketData> _filteredData = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  MarketDataSortOption _sortOption = MarketDataSortOption.symbol;
  MarketData? _selectedMarketData;

  MarketDataProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // Getters
  List<MarketData> get marketData =>
      _searchQuery.isEmpty ? _sortedData : _filteredData;
  List<MarketData> get allMarketData => _marketData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  MarketDataSortOption get sortOption => _sortOption;
  MarketData? get selectedMarketData => _selectedMarketData;
  bool get hasData => _marketData.isNotEmpty;
  bool get hasError => _error != null;

  /// Returns sorted market data based on current sort option.
  List<MarketData> get _sortedData {
    final sorted = List<MarketData>.from(_marketData);
    switch (_sortOption) {
      case MarketDataSortOption.symbol:
        sorted.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case MarketDataSortOption.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case MarketDataSortOption.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case MarketDataSortOption.changeAsc:
        sorted.sort((a, b) => a.changePercent24h.compareTo(b.changePercent24h));
        break;
      case MarketDataSortOption.changeDesc:
        sorted.sort((a, b) => b.changePercent24h.compareTo(a.changePercent24h));
        break;
      case MarketDataSortOption.volumeDesc:
        sorted.sort((a, b) => b.volume.compareTo(a.volume));
        break;
    }
    return sorted;
  }

  /// Loads market data from the API.
  ///
  /// Sets loading state, fetches data, and handles errors.
  /// Calls [notifyListeners] to update the UI.
  Future<void> loadMarketData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getMarketData();
      _marketData = data.map((json) => MarketData.fromJson(json)).toList();
      _applyFilter();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      debugPrint('MarketDataProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes market data (for pull-to-refresh).
  ///
  /// Unlike [loadMarketData], this doesn't clear existing data
  /// during the refresh, providing a smoother UX.
  Future<void> refreshMarketData() async {
    if (_isLoading) return;

    try {
      final data = await _apiService.getMarketData();
      _marketData = data.map((json) => MarketData.fromJson(json)).toList();
      _error = null;
      _applyFilter();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to refresh data. Please try again.';
    } finally {
      notifyListeners();
    }
  }

  /// Sets the search query and filters the data.
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFilter();
    notifyListeners();
  }

  /// Clears the search query.
  void clearSearch() {
    _searchQuery = '';
    _filteredData = [];
    notifyListeners();
  }

  /// Sets the sort option and re-sorts the data.
  void setSortOption(MarketDataSortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      _applyFilter();
      notifyListeners();
    }
  }

  /// Selects a market data item for detail view.
  void selectMarketData(MarketData? data) {
    _selectedMarketData = data;
    notifyListeners();
  }

  /// Clears the selection.
  void clearSelection() {
    _selectedMarketData = null;
    notifyListeners();
  }

  /// Updates a single market data item (for real-time updates).
  void updateMarketData(MarketData updatedData) {
    final index = _marketData.indexWhere((d) => d.symbol == updatedData.symbol);
    if (index != -1) {
      _marketData[index] = updatedData;
      _applyFilter();

      // Update selected item if it matches
      if (_selectedMarketData?.symbol == updatedData.symbol) {
        _selectedMarketData = updatedData;
      }

      notifyListeners();
    }
  }

  /// Updates multiple market data items at once.
  void updateMultipleMarketData(List<MarketData> updates) {
    for (final update in updates) {
      final index = _marketData.indexWhere((d) => d.symbol == update.symbol);
      if (index != -1) {
        _marketData[index] = update;
      }
    }
    _applyFilter();
    notifyListeners();
  }

  /// Clears the error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Applies the current filter and sort to the data.
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredData = [];
      return;
    }

    final query = _searchQuery.toLowerCase();
    _filteredData = _sortedData.where((data) {
      return data.symbol.toLowerCase().contains(query) ||
          data.baseCurrency.toLowerCase().contains(query);
    }).toList();
  }

  /// Returns market data for a specific symbol.
  MarketData? getBySymbol(String symbol) {
    try {
      return _marketData.firstWhere((d) => d.symbol == symbol);
    } catch (_) {
      return null;
    }
  }

  /// Returns the top gainers (highest positive change).
  List<MarketData> getTopGainers({int limit = 5}) {
    final sorted = List<MarketData>.from(_marketData)
      ..sort((a, b) => b.changePercent24h.compareTo(a.changePercent24h));
    return sorted.take(limit).where((d) => d.isPositiveChange).toList();
  }

  /// Returns the top losers (highest negative change).
  List<MarketData> getTopLosers({int limit = 5}) {
    final sorted = List<MarketData>.from(_marketData)
      ..sort((a, b) => a.changePercent24h.compareTo(b.changePercent24h));
    return sorted.take(limit).where((d) => !d.isPositiveChange).toList();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
