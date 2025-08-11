import 'package:flutter/material.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Invoices Screen',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}