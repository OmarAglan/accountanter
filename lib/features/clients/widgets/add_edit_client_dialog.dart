import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for number input filtering
import 'package:drift/drift.dart' hide Column;

class AddEditClientDialog extends StatefulWidget {
  // We need to update the onSave callback to include the balance
  final Function(String name, String email, String type, double balance) onSave;

  const AddEditClientDialog({super.key, required this.onSave});

  @override
  State<AddEditClientDialog> createState() => _AddEditClientDialogState();
}

class _AddEditClientDialogState extends State<AddEditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _balanceController = TextEditingController(); // New controller
  String _selectedType = 'Debtor';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Client'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView( // Wrap in SingleChildScrollView to prevent overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Client Name'),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Client Type'),
                items: ['Debtor', 'Creditor']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // --- NEW FIELD FOR BALANCE ---
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Opening Balance',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final balance = double.tryParse(_balanceController.text) ?? 0.0;
              widget.onSave(
                _nameController.text,
                _emailController.text,
                _selectedType,
                balance, // Pass the new balance value
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save Client'),
        ),
      ],
    );
  }
}