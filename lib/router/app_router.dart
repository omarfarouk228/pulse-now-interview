import 'package:flutter/material.dart';
import '../../models/market_data_model.dart';
import '../../screens/market_detail_screen.dart';
import 'main_shell.dart';

/// Route names for the application.
class AppRoutes {
  static const String home = '/';
  static const String markets = '/markets';
  static const String analytics = '/analytics';
  static const String portfolio = '/portfolio';
  static const String marketDetail = '/market-detail';

  AppRoutes._();
}

/// Application router configuration.
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
      case AppRoutes.markets:
        return MaterialPageRoute(
          builder: (_) => const MainShell(initialIndex: 0),
          settings: settings,
        );

      case AppRoutes.analytics:
        return MaterialPageRoute(
          builder: (_) => const MainShell(initialIndex: 1),
          settings: settings,
        );

      case AppRoutes.portfolio:
        return MaterialPageRoute(
          builder: (_) => const MainShell(initialIndex: 2),
          settings: settings,
        );

      case AppRoutes.marketDetail:
        final marketData = settings.arguments as MarketData;
        return MaterialPageRoute(
          builder: (_) => MarketDetailScreen(marketData: marketData),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const MainShell(initialIndex: 0),
          settings: settings,
        );
    }
  }

  /// Navigate to a named route.
  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and replace the current route.
  static Future<T?> navigateAndReplace<T>(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, dynamic>(
      routeName,
      arguments: arguments,
    );
  }

  /// Pop the current route.
  static void pop<T>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
  }

  /// Pop until a specific route.
  static void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  /// Navigate to market detail screen.
  static void goToMarketDetail(MarketData marketData) {
    navigateTo(AppRoutes.marketDetail, arguments: marketData);
  }
}
