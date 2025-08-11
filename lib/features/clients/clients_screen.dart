import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:accountanter/data/database.dart';
import 'package:accountanter/theme/app_colors.dart';
import 'widgets/client_summary_card.dart';
import 'widgets/add_edit_client_dialog.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final AppDatabase _database = AppDatabase.instance;
  late Stream<List<Client>> _clientsStream;
  String _searchTerm = '';
  String _filterType = 'All Clients';

  @override
  void initState() {
    super.initState();
    _clientsStream = _database.watchAllClients();
  }
  
  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditClientDialog(
        onSave: (name, email, type, balance) {
          final newClient = ClientsCompanion.insert(
            name: name,
            email: Value(email),
            type: type,
            balance: Value(type == 'Creditor' ? -balance : balance),
          );
          _database.insertClient(newClient);
        },
      ),
    );
  }

  void _showEditClientDialog(Client clientToEdit) {
    showDialog(
      context: context,
      builder: (context) => AddEditClientDialog(
        client: clientToEdit, // Pass existing client data to the dialog
        onSave: (name, email, type, balance) {
          final updatedClient = clientToEdit.toCompanion(false).copyWith(
            name: Value(name),
            email: Value(email),
            type: Value(type),
            balance: Value(type == 'Creditor' ? -balance : balance),
          );
          _database.updateClient(updatedClient);
        },
      ),
    );
  }

  void _confirmAndDeleteClient(Client client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Client'),
          content: Text('Are you sure you want to delete "${client.name}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
              child: const Text('Delete'),
              onPressed: () {
                _database.deleteClient(client.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Client>>(
      stream: _clientsStream,
      builder: (context, snapshot) {
        final allClients = snapshot.data ?? [];
        
        final filteredClients = allClients.where((client) {
          final searchLower = _searchTerm.toLowerCase();
          final nameMatches = client.name.toLowerCase().contains(searchLower);
          final emailMatches = client.email?.toLowerCase().contains(searchLower) ?? false;
          final typeMatches = _filterType == 'All Clients' ||
                              (_filterType == 'Debtors' && client.type == 'Debtor') ||
                              (_filterType == 'Creditors' && client.type == 'Creditor');
          return (nameMatches || emailMatches) && typeMatches;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSummaryCards(allClients),
            const SizedBox(height: 24),
            _buildFilterBar(),
            const SizedBox(height: 24),
            _buildClientTable(context, filteredClients, allClients.length),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clients', style: Theme.of(context).textTheme.headlineMedium),
            Text(
              'Manage your client relationships and outstanding balances.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showAddClientDialog,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Add New Client'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.accentForeground,
          ),
        )
      ],
    );
  }

  Widget _buildSummaryCards(List<Client> clients) {
    final totalClients = clients.length;
    final totalReceivables = clients.where((c) => c.balance > 0).fold(0.0, (sum, c) => sum + c.balance);
    final totalPayables = clients.where((c) => c.balance < 0).fold(0.0, (sum, c) => sum + c.balance.abs());
    final debtors = clients.where((c) => c.type == 'Debtor').length;
    final creditors = clients.where((c) => c.type == 'Creditor').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 1100 ? 2 : 4;
        double childAspectRatio = constraints.maxWidth < 600 ? 2.0 : 2.2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: [
            ClientSummaryCard(icon: LucideIcons.users, title: 'Total Clients', value: '$totalClients', color: AppColors.primary),
            ClientSummaryCard(icon: LucideIcons.creditCard, title: 'Total Receivables', value: '\$${totalReceivables.toStringAsFixed(2)}', color: AppColors.success),
            ClientSummaryCard(icon: LucideIcons.banknote, title: 'Total Payables', value: '\$${totalPayables.toStringAsFixed(2)}', color: AppColors.warning),
            ClientSummaryCard(icon: LucideIcons.users, title: 'Client Breakdown', value: '$debtors  /  $creditors', subtitle: 'Debtors / Creditors', color: AppColors.info),
          ],
        );
      }
    );
  }
  
  Widget _buildFilterBar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchTerm = value),
                decoration: const InputDecoration(
                  hintText: 'Search clients by name or email...',
                  prefixIcon: Icon(LucideIcons.search, size: 16),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _filterType,
                decoration: const InputDecoration(isDense: true),
                items: ['All Clients', 'Debtors', 'Creditors']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _filterType = value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientTable(BuildContext context, List<Client> clients, int totalCount) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client List', style: textTheme.titleLarge),
                Text('${clients.length} of $totalCount clients', style: textTheme.bodyMedium),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            color: AppColors.muted.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                _buildHeaderCell('Client Name', flex: 3),
                _buildHeaderCell('Type', flex: 2),
                _buildHeaderCell('Outstanding Balance', flex: 2, alignment: TextAlign.right),
                _buildHeaderCell('Email', flex: 3),
                _buildHeaderCell('Actions', flex: 1, alignment: TextAlign.center),
              ],
            ),
          ),
          const Divider(height: 1),
          if (clients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No clients found.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: clients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final client = clients[index];
                return _buildDataRow(client);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1, TextAlign alignment = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignment,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDataRow(Client client) {
    return InkWell(
      onTap: () { /* For future navigation to client detail page */ },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(client.name)),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(client.type),
                  backgroundColor: client.type == 'Debtor' ? AppColors.info.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
                  labelStyle: TextStyle(color: client.type == 'Debtor' ? AppColors.info : AppColors.accent, fontWeight: FontWeight.w500),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${client.balance < 0 ? '-' : ''}\$${client.balance.abs().toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: client.balance == 0 ? null : (client.balance > 0 ? AppColors.destructive : AppColors.success),
                  fontFamily: 'monospace'
                ),
              ),
            ),
            Expanded(flex: 3, child: Text(client.email ?? 'N/A')),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditClientDialog(client);
                    } else if (value == 'delete') {
                      _confirmAndDeleteClient(client);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem<String>(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.destructive))),
                  ],
                  icon: const Icon(LucideIcons.ellipsisVertical, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}