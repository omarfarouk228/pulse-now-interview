import 'package:flutter/material.dart';

class TimeframeSelector extends StatelessWidget {
  final String selected;
  final List<String> timeframes;
  final ValueChanged<String> onChanged;

  const TimeframeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.timeframes,
  });

  @override
  Widget build(BuildContext context) {
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
