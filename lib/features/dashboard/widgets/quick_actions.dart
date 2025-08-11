import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:accountanter/theme/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.fileText, size: 20),
          label: const Text('Create New Invoice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.accentForeground,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.userPlus, size: 20),
          label: const Text('Add New Client'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
        ),
         OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.package, size: 20),
          label: const Text('Add Inventory Item'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
        ),
      ],
    );
  }
}