import 'package:flutter/material.dart';

class ClientSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const ClientSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'monospace'),
                ),
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
              ],
            )
          ],
        ),
      ),
    );
  }
}