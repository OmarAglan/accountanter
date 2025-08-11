import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Inventory Screen',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}