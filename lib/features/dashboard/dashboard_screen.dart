import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:accountanter/theme/app_colors.dart';
import 'widgets/kpi_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/action_item_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- FIX: Changed ListView back to Column ---
    // The parent SingleChildScrollView in main_screen.dart will handle scrolling.
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
        _buildBottomCards(context),
        const SizedBox(height: 32),
        _buildRecentActivity(context),
      ],
    );
  }

  // ... (All other methods remain exactly the same) ...

  Widget _buildKpiGrid() {
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
          childAspectRatio: (crossAxisCount == 1) ? 3.0 : 2.0,
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

  Widget _buildBottomCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return Column(
            children: [
              _buildCashFlowCard(context),
              const SizedBox(height: 24),
              _buildActionRequiredCard(context),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCashFlowCard(context)),
            const SizedBox(width: 24),
            Expanded(child: _buildActionRequiredCard(context)),
          ],
        );
      },
    );
  }

  Widget _buildCashFlowCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.success, width: 4)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.trendingUp, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text('Cash Flow This Month', style: textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 24),
              _buildCashFlowItem(context, 'Money In', '\$35,650', AppColors.success, true),
              const SizedBox(height: 16),
              _buildCashFlowItem(context, 'Money Out', '\$12,340', AppColors.destructive, false),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net Cash Flow:', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  Text('+\$23,310', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.success, fontFamily: 'monospace')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashFlowItem(BuildContext context, String label, String value, Color color, bool isUp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontFamily: 'monospace', fontSize: 20)),
            ],
          ),
          Icon(isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown, color: color, size: 32),
        ],
      ),
    );
  }

  Widget _buildActionRequiredCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.warning, width: 4)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.triangleAlert, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text('Action Required', style: textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 24),
              const ActionItemCard(
                icon: LucideIcons.circleX,
                color: AppColors.destructive,
                title: '3 Overdue Invoices',
                subtitle: 'Total: \$7,150 - Follow up required',
              ),
              const SizedBox(height: 16),
              const ActionItemCard(
                icon: LucideIcons.triangleAlert,
                color: AppColors.warning,
                title: '5 Invoices Due Soon',
                subtitle: 'Due within 7 days - Send reminders',
              ),
              const SizedBox(height: 16),
              const ActionItemCard(
                icon: LucideIcons.fileText,
                color: AppColors.accent,
                title: '2 Draft Invoices',
                subtitle: 'Ready to be sent to clients',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
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