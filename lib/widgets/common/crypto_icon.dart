import 'package:flutter/material.dart';
import 'package:pulsenow_flutter/themes/app_theme.dart';

class CryptoIcon extends StatelessWidget {
  final String symbol;
  final double radius;

  const CryptoIcon({super.key, required this.symbol, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _getColorForSymbol(symbol),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.65,
          ),
        ),
      ),
    );
  }

  Color _getColorForSymbol(String symbol) {
    // Generate a consistent color based on the symbol
    final hash = symbol.hashCode;
    final colors = AppTheme.symbolColors;
    return colors[hash.abs() % colors.length];
  }
}
