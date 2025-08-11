import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;

class AddEditClientDialog extends StatefulWidget {
  final Function(String name, String email, String type) onSave;

  const AddEditClientDialog({super.key, required this.onSave});

  @override
  State<AddEditClientDialog> createState() => _AddEditClientDialogState();
}

class _AddEditClientDialogState extends State<AddEditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedType = 'Debtor';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Client'),
      content: Form(
        key: _formKey,
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
          ],
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
              widget.onSave(
                _nameController.text,
                _emailController.text,
                _selectedType,
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