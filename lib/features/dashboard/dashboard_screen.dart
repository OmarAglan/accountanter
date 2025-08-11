import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:accountanter/theme/app_colors.dart';
import 'widgets/kpi_card.dart';
import 'widgets/quick_actions.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        const QuickActions(),
        const SizedBox(height: 32),
        Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildKpiGrid(),
        const SizedBox(height: 32),
        _buildRecentActivity(context),
        // TODO: Add Cash Flow and Action Required cards later
      ],
    );
  }

  Widget _buildKpiGrid() {
    // This uses LayoutBuilder to create a responsive grid
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 1200) crossAxisCount = 2;
        if (constraints.maxWidth < 600) crossAxisCount = 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.0, // Adjust this ratio as needed
          children: const [
            KpiCard(
              title: 'Total Receivables',
              value: '\$47,890',
              change: '+12.5%',
              isPositiveChange: true,
              icon: LucideIcons.dollarSign,
              borderColor: AppColors.success,
            ),
            KpiCard(
              title: 'Total Payables',
              value: '\$12,340',
              change: '-8.2%',
              isPositiveChange: false,
              icon: LucideIcons.trendingUp,
              borderColor: AppColors.warning,
            ),
            KpiCard(
              title: 'Overdue Invoices',
              value: '3',
              change: '+1',
              isPositiveChange: false,
              icon: LucideIcons.triangleAlert,
              borderColor: AppColors.destructive,
            ),
            KpiCard(
              title: 'Active Clients',
              value: '47',
              change: '+3',
              isPositiveChange: true,
              icon: LucideIcons.users,
              borderColor: AppColors.primary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    // Mock data from your React component
    final activities = [
      {'icon': LucideIcons.circleCheck, 'color': AppColors.success, 'title': 'Invoice #1024 paid', 'subtitle': '\$2,500 from Acme Corp', 'time': '2 hours ago'},
      {'icon': LucideIcons.users, 'color': AppColors.info, 'title': "New client 'Tech Solutions' added", 'subtitle': 'Contact: hello@techsolutions.com', 'time': '4 hours ago'},
      {'icon': LucideIcons.fileText, 'color': AppColors.info, 'title': 'Invoice #1025 created', 'subtitle': '\$1,800 for Design Studio LLC', 'time': '6 hours ago'},
      {'icon': LucideIcons.circleX, 'color': AppColors.destructive, 'title': 'Invoice #1020 is overdue', 'subtitle': '\$3,200 from Marketing Agency', 'time': '1 day ago'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
             Text(
              'Latest updates and transactions',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ListView.separated(
              itemCount: activities.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 20),
                  ),
                  title: Text(activity['title'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(activity['subtitle'] as String),
                  trailing: Text(activity['time'] as String, style: Theme.of(context).textTheme.bodyMedium),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}