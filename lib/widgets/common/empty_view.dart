import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final String message;
  final String title;
  final IconData icon;
  final VoidCallback onRefresh;

  const EmptyView({
    super.key,
    required this.onRefresh,
    this.message = 'No data available. Pull down to refresh.',
    this.title = 'Nothing to See Here',
    this.icon = Icons.visibility_off_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Data'),
            ),
          ],
        ),
      ),
    );
  }
}
