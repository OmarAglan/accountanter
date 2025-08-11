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
  late final AppDatabase _database;
  late Stream<List<Client>> _clientsStream;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _clientsStream = _database.watchAllClients();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
  
  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditClientDialog(
        onSave: (name, email, type) {
          final newClient = ClientsCompanion.insert(
            name: name,
            email: Value(email),
            type: type,
          );
          _database.insertClient(newClient);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Client>>(
      stream: _clientsStream,
      builder: (context, snapshot) {
        final clients = snapshot.data ?? [];
        
        // --- FIX: Changed ListView to Column ---
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSummaryCards(clients),
            const SizedBox(height: 24),
            _buildClientTable(context, clients),
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
              'Manage your client relationships and balances.',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 1100 ? 2 : 4;
        double childAspectRatio = constraints.maxWidth < 600 ? 2.0 : 2.5;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: [
            ClientSummaryCard(icon: LucideIcons.users, title: 'Total Clients', value: '$totalClients', color: AppColors.primary),
            ClientSummaryCard(icon: LucideIcons.trendingUp, title: 'Total Receivables', value: '\$${totalReceivables.toStringAsFixed(2)}', color: AppColors.success),
            ClientSummaryCard(icon: LucideIcons.trendingDown, title: 'Total Payables', value: '\$${totalPayables.toStringAsFixed(2)}', color: AppColors.warning),
            ClientSummaryCard(icon: LucideIcons.userCheck, title: 'Debtors', value: '$debtors', color: AppColors.info),
          ],
        );
      }
    );
  }

  Widget _buildClientTable(BuildContext context, List<Client> clients) {
    return Card(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Client Name')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Balance'), numeric: true),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Actions')),
        ],
        rows: clients.map((client) => DataRow(
          cells: [
            DataCell(Text(client.name)),
            DataCell(
              Chip(
                label: Text(client.type),
                backgroundColor: client.type == 'Debtor' ? AppColors.info.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
                labelStyle: TextStyle(color: client.type == 'Debtor' ? AppColors.info : AppColors.accent),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                visualDensity: VisualDensity.compact,
              ),
            ),
            DataCell(Text(
              '${client.balance < 0 ? '-' : ''}\$${client.balance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: client.balance == 0 ? null : (client.balance > 0 ? AppColors.destructive : AppColors.success),
                fontFamily: 'monospace'
              ),
            )),
            DataCell(Text(client.email ?? 'N/A')),
            DataCell(Row(
              children: [
                IconButton(icon: const Icon(LucideIcons.filePenLine, size: 16), onPressed: () { /* TODO: Edit */ }),
                IconButton(icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.destructive), onPressed: () { /* TODO: Delete */ }),
              ],
            )),
          ]
        )).toList(),
      ),
    );
  }
}