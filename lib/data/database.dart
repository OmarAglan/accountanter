import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users.dart';
import 'tables/licenses.dart';
import 'tables/clients.dart';
import 'tables/expenses.dart';
import 'tables/inventory_items.dart';
import 'tables/invoices.dart';
import 'tables/line_items.dart';
import 'tables/categories.dart';
import 'tables/suppliers.dart';
import 'tables/vendors.dart';
import 'tables/payments.dart';
import 'tables/recurring_invoices.dart';
import 'tables/tax_rates.dart';
import 'tables/documents.dart';
import 'tables/settings_entries.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Users,
  Licenses,
  Clients,
  Expenses,
  InventoryItems,
  Invoices,
  LineItems,
  Categories,
  Suppliers,
  Vendors,
  Payments,
  RecurringInvoices,
  TaxRates,
  Documents,
  SettingsEntries,
])
class AppDatabase extends _$AppDatabase {
  // --- SINGLETON SETUP START ---
  AppDatabase._internal() : super(_openConnection());
  static final AppDatabase instance = AppDatabase._internal();
  // --- SINGLETON SETUP END ---

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  factory AppDatabase() {
    return instance;
  }

  @override
  int get schemaVersion => 11; // INCREMENT SCHEMA VERSION

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // ... previous migrations
        if (from < 2) {
          await m.createTable(licenses);
          await m.drop(users);
          await m.createTable(users);
        }
        if (from < 3) {
          await m.createTable(clients);
        }
        if (from < 4) {
          await m.createTable(expenses);
        }
        if (from < 5) {
          await m.createTable(inventoryItems);
        }
        if (from < 6) {
          await m.createTable(invoices);
          await m.createTable(lineItems);
        }
        if (from < 7) {
          await m.createTable(categories);
          await m.createTable(suppliers);
          await m.addColumn(inventoryItems, inventoryItems.categoryId);
          await m.addColumn(inventoryItems, inventoryItems.supplierId);
        }
        // NEW MIGRATION LOGIC
        if (from < 8) {
          // 1. Create new vendors table
          await m.createTable(vendors);

          // 2. Add new foreign key columns to expenses table
          await m.addColumn(expenses, expenses.categoryId);
          await m.addColumn(expenses, expenses.vendorId);

          // In a real production app with data, you would now write a script here
          // to read the old text values from the original `category` and `vendor`
          // columns, create corresponding entries in the new `categories` and
          // `vendors` tables, and then update the new `categoryId` and `vendorId`
          // columns with the new foreign keys.
          // Since this app is in early development, we can skip this data migration.
        }
        if (from < 9) {
          await m.createTable(payments);
          await m.createTable(recurringInvoices);
          await m.createTable(taxRates);
          await m.createTable(documents);
          await m.createTable(settingsEntries);
        }
        if (from < 10) {
          await m.addColumn(invoices, invoices.discountAmount);
        }
        if (from < 11) {
          await m.addColumn(lineItems, lineItems.inventoryItemId);
        }
      },
    );
  }

  // All other database methods remain the same...

  // --- Dashboard Data Fetching ---
  Future<DashboardData> getDashboardData() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final totalReceivablesFuture = getTotalReceivables();
    final totalPayablesFuture = getTotalPayables();
    final activeClientsCountFuture = getActiveClientsCount();
    
    final overdueInvoicesCountFuture = (select(invoices)..where((i) => i.status.equals('Overdue'))).get().then((l) => l.length);
    final invoicesDueSoonCountFuture = (select(invoices)..where((i) => i.status.equals('Pending') & i.dueDate.isSmallerThanValue(now.add(const Duration(days: 7))))).get().then((l) => l.length);
    final draftInvoicesCountFuture = (select(invoices)..where((i) => i.status.equals('Draft'))).get().then((l) => l.length);

    final moneyInExpr = invoices.totalAmount.sum();
    final moneyInQuery = selectOnly(invoices)..addColumns([moneyInExpr])..where(invoices.status.equals('Paid') & invoices.issueDate.isBiggerOrEqualValue(startOfMonth));
    final moneyInFuture = moneyInQuery.map((row) => row.read(moneyInExpr) ?? 0.0).getSingle();

    final moneyOutExpr = expenses.amount.sum();
    final moneyOutQuery = selectOnly(expenses)..addColumns([moneyOutExpr])..where(expenses.date.isBiggerOrEqualValue(startOfMonth));
    final moneyOutFuture = moneyOutQuery.map((row) => row.read(moneyOutExpr) ?? 0.0).getSingle();

    final recentInvoicesFuture = (select(invoices)..orderBy([(i) => OrderingTerm.desc(i.createdAt)])..limit(2)).get();
    final recentClientsFuture = (select(clients)..orderBy([(c) => OrderingTerm.desc(c.createdAt)])..limit(2)).get();
    final recentExpensesFuture = (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.createdAt)])..limit(2)).get();

    final results = await Future.wait([
      totalReceivablesFuture, totalPayablesFuture, activeClientsCountFuture,
      overdueInvoicesCountFuture, invoicesDueSoonCountFuture, draftInvoicesCountFuture,
      moneyInFuture, moneyOutFuture,
      recentInvoicesFuture, recentClientsFuture, recentExpensesFuture,
    ]);

    final allActivities = [
      ...(results[8] as List<Invoice>).map((i) => RecentActivity(date: i.createdAt, type: ActivityType.invoice, description: 'Invoice ${i.invoiceNumber} created', amount: i.totalAmount)),
      ...(results[9] as List<Client>).map((c) => RecentActivity(date: c.createdAt, type: ActivityType.client, description: 'New client added: ${c.name}', amount: c.balance)),
      ...(results[10] as List<Expense>).map((e) => RecentActivity(date: e.createdAt, type: ActivityType.expense, description: e.description, amount: -e.amount)),
    ];

    allActivities.sort((a, b) => b.date.compareTo(a.date));


    final totalReceivables = results[0] as double;

    return DashboardData(
      totalReceivables: totalReceivables,
      totalPayables: results[1] as double,
      totalOutstandingBalance: totalReceivables,
      activeClients: results[2] as int,
      overdueInvoicesCount: results[3] as int,
      invoicesDueSoonCount: results[4] as int,
      draftInvoicesCount: results[5] as int,
      moneyInThisMonth: results[6] as double,
      moneyOutThisMonth: results[7] as double,
      recentActivities: allActivities.take(5).toList(),
    );
  }


  // --- KPI Methods (used by getDashboardData) ---
  Future<ClientBalanceTotals> getClientBalanceTotals() async {
    final clients = await getAllClientsWithBalance();
    var receivables = 0.0;
    var payables = 0.0;

    for (final client in clients) {
      final balance = client.currentBalance;
      if (balance > 0) {
        receivables += balance;
      } else if (balance < 0) {
        payables += balance.abs();
      }
    }

    return ClientBalanceTotals(receivables: receivables, payables: payables);
  }

  Future<double> getTotalReceivables() async {
    return (await getClientBalanceTotals()).receivables;
  }

  Future<double> getTotalPayables() async {
    return (await getClientBalanceTotals()).payables;
  }

  Future<int> getActiveClientsCount() {
    final count = clients.id.count();
    final query = selectOnly(clients)..addColumns([count]);
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  // --- Client Methods ---
  Future<List<Client>> getAllClients() => select(clients).get();
  Stream<List<Client>> watchAllClients() => select(clients).watch();
  Future<List<ClientWithBalance>> getAllClientsWithBalance() async {
    final allClients = await getAllClients();
    final balances = await _getCurrentBalancesByClientId();
    return allClients
        .map((client) => ClientWithBalance(
              client: client,
              currentBalance: balances[client.id] ?? client.balance,
            ))
        .toList();
  }

  Stream<List<ClientWithBalance>> watchAllClientsWithBalance() {
    return _clientBalanceRows().watch().asyncMap((rows) async {
      final allClients = await getAllClients();
      final balances = _mapCurrentBalancesByClientId(rows);
      return allClients
          .map((client) => ClientWithBalance(
                client: client,
                currentBalance: balances[client.id] ?? client.balance,
              ))
          .toList();
    });
  }

  Future<Map<int, double>> _getCurrentBalancesByClientId() async {
    return _mapCurrentBalancesByClientId(await _clientBalanceRows().get());
  }

  Map<int, double> _mapCurrentBalancesByClientId(List<QueryRow> rows) {
    return {
      for (final row in rows)
        row.read<int>('client_id'): row.read<double>('current_balance'),
    };
  }

  Selectable<QueryRow> _clientBalanceRows() {
    return customSelect(
      '''
      SELECT
        c.id AS client_id,
        c.balance + COALESCE(
          SUM(
            CASE
              WHEN i.status != 'Draft'
              THEN i.total_amount - COALESCE(p.paid_amount, 0.0)
              ELSE 0.0
            END
          ),
          0.0
        ) AS current_balance
      FROM clients c
      LEFT JOIN invoices i ON i.client_id = c.id
      LEFT JOIN (
        SELECT invoice_id, SUM(amount) AS paid_amount
        FROM payments
        GROUP BY invoice_id
      ) p ON p.invoice_id = i.id
      GROUP BY c.id, c.balance
      ''',
      readsFrom: {clients, invoices, payments},
    );
  }

  Future<int> insertClient(ClientsCompanion client) =>
      into(clients).insert(client);
  Future<bool> updateClient(ClientsCompanion client) =>
      update(clients).replace(client);
  Future<int> deleteClient(int id) =>
      (delete(clients)..where((c) => c.id.equals(id))).go();

  // --- Expense Methods ---
  Future<List<Expense>> getAllExpenses() => select(expenses).get();
  Stream<List<Expense>> watchAllExpenses() => select(expenses).watch();
  Future<int> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);
  Future<bool> updateExpense(ExpensesCompanion expense) =>
      update(expenses).replace(expense);
  Future<int> deleteExpense(int id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();

  // --- Inventory Methods ---
  Stream<List<InventoryItem>> watchAllInventoryItems() =>
      select(inventoryItems).watch();
  Future<int> insertInventoryItem(InventoryItemsCompanion item) =>
      into(inventoryItems).insert(item);
  Future<bool> updateInventoryItem(InventoryItemsCompanion item) =>
      update(inventoryItems).replace(item);
  Future<int> deleteInventoryItem(int id) =>
      (delete(inventoryItems)..where((i) => i.id.equals(id))).go();

  // --- Invoice & Line Item Methods ---
  Stream<List<InvoiceWithStats>> watchAllInvoicesWithStats() {
    final paidAmount = CustomExpression<double>('(SELECT SUM(amount) FROM payments WHERE invoice_id = invoices.id)');
    
    final query = select(invoices).join([
      innerJoin(clients, clients.id.equalsExp(invoices.clientId)),
    ]);
    
    query.addColumns([paidAmount]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return InvoiceWithStats(
          invoice: row.readTable(invoices),
          client: row.readTable(clients),
          paidAmount: row.read(paidAmount) ?? 0.0,
        );
      }).toList();
    });
  }
  
  Future<InvoiceDetails?> getInvoiceDetails(int invoiceId) async {
    final invoiceQuery = select(invoices)..where((i) => i.id.equals(invoiceId));
    final invoiceResult = await invoiceQuery.getSingleOrNull();
    if (invoiceResult == null) return null;
    final clientQuery = select(clients)..where((c) => c.id.equals(invoiceResult.clientId));
    final clientResult = await clientQuery.getSingle();
    final lineItemsQuery = select(lineItems)..where((l) => l.invoiceId.equals(invoiceId));
    final lineItemsResult = await lineItemsQuery.get();
    return InvoiceDetails(invoice: invoiceResult, client: clientResult, lineItems: lineItemsResult);
  }

  Future<void> createOrUpdateInvoice(
    InvoicesCompanion invoice,
    List<LineItemsCompanion> items,
  ) {
    return transaction(() async {
      final int invoiceId;

      if (invoice.id.present) {
        invoiceId = invoice.id.value;
        await update(invoices).replace(invoice);
      } else {
        invoiceId = await into(invoices).insert(invoice);
      }

      final previousLineItems =
          await (select(lineItems)..where((l) => l.invoiceId.equals(invoiceId)))
              .get();

      for (final li in previousLineItems) {
        final inventoryItemId = li.inventoryItemId;
        if (inventoryItemId == null) continue;
        await _adjustInventoryQuantity(inventoryItemId, li.quantity);
      }

      await (delete(lineItems)..where((l) => l.invoiceId.equals(invoiceId))).go();

      for (final item in items) {
        await into(lineItems).insert(item.copyWith(invoiceId: Value(invoiceId)));

        final inventoryItemId =
            item.inventoryItemId.present ? item.inventoryItemId.value : null;
        if (inventoryItemId == null) continue;

        await _adjustInventoryQuantity(inventoryItemId, -item.quantity.value);
      }

      await _recalculateInvoicePaymentStatus(invoiceId);
    });
  }

  Future<void> _adjustInventoryQuantity(int inventoryItemId, int delta) async {
    final existing = await (select(inventoryItems)
          ..where((i) => i.id.equals(inventoryItemId)))
        .getSingleOrNull();
    if (existing == null) return;

    final next = existing.quantity + delta;
    if (next < 0) {
      throw StateError('Insufficient stock for "${existing.name}".');
    }

    await (update(inventoryItems)..where((i) => i.id.equals(inventoryItemId)))
        .write(InventoryItemsCompanion(quantity: Value(next)));
  }

  Future<void> deleteInvoice(int invoiceId) {
    return transaction(() async {
      final existingLineItems =
          await (select(lineItems)..where((l) => l.invoiceId.equals(invoiceId)))
              .get();

      for (final li in existingLineItems) {
        final inventoryItemId = li.inventoryItemId;
        if (inventoryItemId == null) continue;
        await _adjustInventoryQuantity(inventoryItemId, li.quantity);
      }

      await (delete(payments)..where((p) => p.invoiceId.equals(invoiceId))).go();
      await (delete(lineItems)..where((l) => l.invoiceId.equals(invoiceId))).go();
      await (delete(invoices)..where((i) => i.id.equals(invoiceId))).go();
    });
  }

  // --- Recurring Invoice Methods ---
  Stream<List<RecurringInvoiceWithClient>> watchAllRecurringInvoices() {
     final query = select(recurringInvoices).join(
        [innerJoin(clients, clients.id.equalsExp(recurringInvoices.clientId))]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return RecurringInvoiceWithClient(
          recurringInvoice: row.readTable(recurringInvoices),
          client: row.readTable(clients),
        );
      }).toList();
    });
  }
  
  Future<int> insertRecurringInvoice(RecurringInvoicesCompanion entry) =>
      into(recurringInvoices).insert(entry);
      
  Future<bool> updateRecurringInvoice(RecurringInvoicesCompanion entry) =>
      update(recurringInvoices).replace(entry);
      
  Future<int> deleteRecurringInvoice(int id) =>
      (delete(recurringInvoices)..where((i) => i.id.equals(id))).go();

  // --- Payment Methods ---
  Stream<List<PaymentWithInvoiceAndClient>> watchAllPaymentsWithInvoiceAndClient() {
    final query = select(payments).join([
      innerJoin(invoices, invoices.id.equalsExp(payments.invoiceId)),
      innerJoin(clients, clients.id.equalsExp(invoices.clientId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return PaymentWithInvoiceAndClient(
          payment: row.readTable(payments),
          invoice: row.readTable(invoices),
          client: row.readTable(clients),
        );
      }).toList();
    });
  }

  Future<int> insertPayment(PaymentsCompanion payment) {
    return transaction(() async {
      final paymentId = await into(payments).insert(payment);
      await _recalculateInvoicePaymentStatus(payment.invoiceId.value);
      return paymentId;
    });
  }

  Future<bool> updatePayment(PaymentsCompanion payment) {
    return transaction(() async {
      final existing = payment.id.present
          ? await (select(payments)..where((p) => p.id.equals(payment.id.value)))
              .getSingleOrNull()
          : null;
      final ok = await update(payments).replace(payment);
      final oldInvoiceId = existing?.invoiceId;
      final newInvoiceId = payment.invoiceId.value;
      if (oldInvoiceId != null && oldInvoiceId != newInvoiceId) {
        await _recalculateInvoicePaymentStatus(oldInvoiceId);
      }
      await _recalculateInvoicePaymentStatus(newInvoiceId);
      return ok;
    });
  }

  Future<int> deletePayment(int paymentId) {
    return transaction(() async {
      final existing = await (select(payments)..where((p) => p.id.equals(paymentId))).getSingleOrNull();
      if (existing == null) return 0;
      final invoiceId = existing.invoiceId;
      final deleted = await (delete(payments)..where((p) => p.id.equals(paymentId))).go();
      await _recalculateInvoicePaymentStatus(invoiceId);
      return deleted;
    });
  }

  Future<void> _recalculateInvoicePaymentStatus(int invoiceId) async {
    final invoice = await (select(invoices)..where((i) => i.id.equals(invoiceId))).getSingleOrNull();
    if (invoice == null) return;

    final paidExpr = payments.amount.sum();
    final paidQuery = selectOnly(payments)
      ..addColumns([paidExpr])
      ..where(payments.invoiceId.equals(invoiceId));
    final paid = await paidQuery.map((row) => row.read(paidExpr) ?? 0.0).getSingle();

    String? nextStatus;
    if (paid >= invoice.totalAmount && invoice.status != 'Paid') {
      nextStatus = 'Paid';
    } else if (paid > 0 && invoice.status == 'Draft') {
      nextStatus = 'Pending';
    } else if (paid < invoice.totalAmount && invoice.status == 'Paid') {
      nextStatus = 'Pending';
    }

    if (nextStatus != null) {
      await (update(invoices)..where((i) => i.id.equals(invoiceId))).write(InvoicesCompanion(status: Value(nextStatus)));
    }
  }

  // --- Tax Rate Methods ---
  Stream<List<TaxRate>> watchAllTaxRates() {
    return (select(taxRates)
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDefault),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Future<int> insertTaxRate(TaxRatesCompanion entry) => into(taxRates).insert(entry);
  Future<bool> updateTaxRate(TaxRatesCompanion entry) => update(taxRates).replace(entry);
  Future<int> deleteTaxRate(int id) => (delete(taxRates)..where((t) => t.id.equals(id))).go();

  Future<void> setDefaultTaxRate(int id) {
    return transaction(() async {
      await (update(taxRates)).write(const TaxRatesCompanion(isDefault: Value(false)));
      await (update(taxRates)..where((t) => t.id.equals(id))).write(const TaxRatesCompanion(isDefault: Value(true)));
    });
  }

  Future<TaxRate?> getDefaultTaxRate() {
    return (select(taxRates)..where((t) => t.isDefault.equals(true))).getSingleOrNull();
  }

  // --- Document Methods ---
  Stream<List<Document>> watchAllDocuments() {
    return (select(documents)..orderBy([(d) => OrderingTerm.desc(d.uploadDate)])).watch();
  }

  Future<int> insertDocument(DocumentsCompanion entry) => into(documents).insert(entry);
  Future<bool> updateDocument(DocumentsCompanion entry) => update(documents).replace(entry);
  Future<int> deleteDocument(int id) => (delete(documents)..where((d) => d.id.equals(id))).go();

  // --- Settings Methods ---
  Future<SettingsEntry?> getSettingEntry(String key) {
    return (select(settingsEntries)..where((s) => s.key.equals(key))).getSingleOrNull();
  }

  Future<void> setSettingEntry(SettingsEntriesCompanion entry) {
    return into(settingsEntries).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Future<String?> getSettingString(String key) async {
    final entry = await getSettingEntry(key);
    if (entry == null) return null;
    return entry.value;
  }

  Future<void> setSettingString(String key, String value) {
    return setSettingEntry(SettingsEntriesCompanion(
      key: Value(key),
      value: Value(value),
      type: const Value('string'),
    ));
  }

  Future<double?> getSettingDouble(String key) async {
    final v = await getSettingString(key);
    if (v == null) return null;
    return double.tryParse(v);
  }

  Future<void> setSettingDouble(String key, double value) {
    return setSettingString(key, value.toString());
  }

  Future<bool?> getSettingBool(String key) async {
    final v = await getSettingString(key);
    if (v == null) return null;
    if (v.toLowerCase() == 'true') return true;
    if (v.toLowerCase() == 'false') return false;
    return null;
  }

  Future<void> setSettingBool(String key, bool value) {
    return setSettingString(key, value.toString());
  }

  Future<String> getCurrencySymbol() async {
    final symbol = await getSettingString('currency.symbol');
    if (symbol == null || symbol.trim().isEmpty) return '\$';
    return symbol.trim();
  }

  Future<bool> isDemoModeEnabled() async {
    final v = await getSettingBool('demo.mode');
    return v ?? false;
  }

  // --- Report Methods ---
  Future<List<MonthlyTotal>> getPaidRevenueByMonth({int monthsBack = 12}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (monthsBack - 1), 1);
    final paidInvoices = await (select(invoices)
          ..where((i) => i.status.equals('Paid') & i.issueDate.isBiggerOrEqualValue(start)))
        .get();

    final Map<MonthKey, double> totals = {};
    for (final inv in paidInvoices) {
      final key = MonthKey(inv.issueDate.year, inv.issueDate.month);
      totals[key] = (totals[key] ?? 0.0) + inv.totalAmount;
    }
    final sortedKeys = totals.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    return sortedKeys.map((k) => MonthlyTotal(year: k.year, month: k.month, total: totals[k] ?? 0.0)).toList();
  }

  Future<List<MonthlyTotal>> getExpensesByMonth({int monthsBack = 12}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (monthsBack - 1), 1);
    final all = await (select(expenses)..where((e) => e.date.isBiggerOrEqualValue(start))).get();

    final Map<MonthKey, double> totals = {};
    for (final e in all) {
      final key = MonthKey(e.date.year, e.date.month);
      totals[key] = (totals[key] ?? 0.0) + e.amount;
    }
    final sortedKeys = totals.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    return sortedKeys.map((k) => MonthlyTotal(year: k.year, month: k.month, total: totals[k] ?? 0.0)).toList();
  }

  // --- Auth & System Methods ---
  Future<License?> getLicense() =>
      (select(licenses)..where((l) => l.id.equals(1))).getSingleOrNull();
  Future<void> saveLicense(LicensesCompanion license) =>
      into(licenses).insert(license, mode: InsertMode.replace);
  Future<User?> getLocalUser() => (select(users)).getSingleOrNull();
  Future<void> createLocalUser(UsersCompanion user) => into(users).insert(user);
  Future<void> updateLocalUserPasswordHash(int id, String passwordHash) {
    return (update(users)..where((u) => u.id.equals(id))).write(UsersCompanion(passwordHash: Value(passwordHash)));
  }
  Future<void> factoryReset() async {
    return transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

class InvoiceWithStats {
  final Invoice invoice;
  final Client client;
  final double paidAmount;
  
  InvoiceWithStats({
    required this.invoice,
    required this.client,
    required this.paidAmount,
  });

  double get balance => invoice.totalAmount - paidAmount;
}

class ClientWithBalance {
  final Client client;
  final double currentBalance;

  ClientWithBalance({
    required this.client,
    required this.currentBalance,
  });

  double get openingBalance => client.balance;
}

class ClientBalanceTotals {
  final double receivables;
  final double payables;

  ClientBalanceTotals({
    required this.receivables,
    required this.payables,
  });
}

class InvoiceDetails {
  final Invoice invoice;
  final Client client;
  final List<LineItem> lineItems;
  InvoiceDetails({required this.invoice, required this.client, required this.lineItems});
}

class RecurringInvoiceWithClient {
  final RecurringInvoice recurringInvoice;
  final Client client;
  RecurringInvoiceWithClient({required this.recurringInvoice, required this.client});
}

class PaymentWithInvoiceAndClient {
  final Payment payment;
  final Invoice invoice;
  final Client client;
  PaymentWithInvoiceAndClient({required this.payment, required this.invoice, required this.client});
}

class MonthKey implements Comparable<MonthKey> {
  final int year;
  final int month;
  const MonthKey(this.year, this.month);

  @override
  int compareTo(MonthKey other) {
    final c = year.compareTo(other.year);
    if (c != 0) return c;
    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) => other is MonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

class MonthlyTotal {
  final int year;
  final int month;
  final double total;
  MonthlyTotal({required this.year, required this.month, required this.total});
}

enum ActivityType { invoice, client, expense }

class RecentActivity {
  final DateTime date;
  final ActivityType type;
  final String description;
  final double amount;
  RecentActivity({required this.date, required this.type, required this.description, required this.amount});
}

class DashboardData {
  final double totalReceivables;
  final double totalPayables;
  final double totalOutstandingBalance;
  final int activeClients;
  final int overdueInvoicesCount;
  final int invoicesDueSoonCount;
  final int draftInvoicesCount;
  final double moneyInThisMonth;
  final double moneyOutThisMonth;
  final List<RecentActivity> recentActivities;

  DashboardData({
    required this.totalReceivables,
    required this.totalPayables,
    required this.totalOutstandingBalance,
    required this.activeClients,
    required this.overdueInvoicesCount,
    required this.invoicesDueSoonCount,
    required this.draftInvoicesCount,
    required this.moneyInThisMonth,
    required this.moneyOutThisMonth,
    required this.recentActivities,
  });
}


LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'accountanter.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
