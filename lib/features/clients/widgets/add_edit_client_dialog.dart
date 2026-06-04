import 'package:flutter/material.dart';
import 'package:accountanter/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../../data/database.dart';

class AddEditClientDialog extends StatefulWidget {
  final Client? client; // Optional client for editing
  final Function(String name, String email, String type, double balance) onSave;

  const AddEditClientDialog({super.key, this.client, required this.onSave});

  @override
  State<AddEditClientDialog> createState() => _AddEditClientDialogState();
}

class _AddEditClientDialogState extends State<AddEditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final AppDatabase _database = AppDatabase.instance;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'Debtor';
  bool get _isEditing => widget.client != null;
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
    if (_isEditing) {
      _nameController.text = widget.client!.name;
      _emailController.text = widget.client!.email ?? '';
      _balanceController.text = widget.client!.balance.abs().toStringAsFixed(2);
      _selectedType = widget.client!.type;
    }
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await _database.getCurrencySymbol();
    if (!mounted) return;
    setState(() => _currencySymbol = symbol);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _balanceController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? AppLocalizations.of(context)!.editClient : AppLocalizations.of(context)!.addNewClient),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.clientName),
                validator: (v) => v!.isEmpty ? AppLocalizations.of(context)!.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: '${AppLocalizations.of(context)!.email} / ${AppLocalizations.of(context)!.phone}'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedType),
                initialValue: _selectedType,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.client),
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
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Opening Balance',
                  prefixText: _currencySymbol,
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final balance = double.tryParse(_balanceController.text) ?? 0.0;
              widget.onSave(
                _nameController.text,
                _emailController.text,
                _selectedType,
                balance,
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(_isEditing ? AppLocalizations.of(context)!.update : AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
