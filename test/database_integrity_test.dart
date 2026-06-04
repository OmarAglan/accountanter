import 'package:accountanter/data/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  final now = DateTime(2026, 1, 1);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createClient({
    String name = 'Acme',
    String type = 'Debtor',
    double openingBalance = 0,
  }) {
    return database.insertClient(
      ClientsCompanion.insert(
        name: name,
        type: type,
        balance: Value(openingBalance),
      ),
    );
  }

  Future<int> createInventoryItem({int quantity = 5}) async {
    final categoryId = await database.into(database.categories).insert(
          CategoriesCompanion.insert(name: 'Goods', type: 'inventory'),
        );
    return database.insertInventoryItem(
      InventoryItemsCompanion.insert(
        name: 'Widget',
        categoryId: categoryId,
        quantity: quantity,
        unitPrice: 10,
      ),
    );
  }

  LineItemsCompanion lineItem({
    int? inventoryItemId,
    int quantity = 1,
    double unitPrice = 100,
  }) {
    return LineItemsCompanion(
      inventoryItemId: inventoryItemId == null
          ? const Value.absent()
          : Value(inventoryItemId),
      description: const Value('Line item'),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      total: Value(quantity * unitPrice),
    );
  }

  Future<Invoice> createInvoice({
    required int clientId,
    String invoiceNumber = 'INV-1',
    String status = 'Pending',
    double total = 100,
    List<LineItemsCompanion>? items,
  }) async {
    await database.createOrUpdateInvoice(
      InvoicesCompanion.insert(
        invoiceNumber: invoiceNumber,
        clientId: clientId,
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        totalAmount: total,
        taxAmount: 0,
        subtotal: total,
        status: status,
      ),
      items ?? [lineItem(unitPrice: total)],
    );

    return (database.select(database.invoices)
          ..where((i) => i.invoiceNumber.equals(invoiceNumber)))
        .getSingle();
  }

  Future<int> inventoryQuantity(int inventoryItemId) async {
    final item = await (database.select(database.inventoryItems)
          ..where((i) => i.id.equals(inventoryItemId)))
        .getSingle();
    return item.quantity;
  }

  test('create, edit, and delete invoice keep inventory quantities balanced',
      () async {
    final clientId = await createClient();
    final inventoryItemId = await createInventoryItem(quantity: 5);

    final invoice = await createInvoice(
      clientId: clientId,
      total: 20,
      items: [
        lineItem(inventoryItemId: inventoryItemId, quantity: 2, unitPrice: 10),
      ],
    );

    expect(await inventoryQuantity(inventoryItemId), 3);

    await database.createOrUpdateInvoice(
      invoice.toCompanion(false).copyWith(
            totalAmount: const Value(40),
            subtotal: const Value(40),
          ),
      [
        lineItem(inventoryItemId: inventoryItemId, quantity: 4, unitPrice: 10),
      ],
    );

    expect(await inventoryQuantity(inventoryItemId), 1);

    await database.insertPayment(
      PaymentsCompanion.insert(
        invoiceId: invoice.id,
        amount: 10,
        date: now,
        method: 'Cash',
      ),
    );

    await database.deleteInvoice(invoice.id);

    expect(await inventoryQuantity(inventoryItemId), 5);
    expect((await database.select(database.lineItems).get()).length, 0);
    expect((await database.select(database.payments).get()).length, 0);
    expect((await database.select(database.invoices).get()).length, 0);
  });

  test('insufficient stock rolls back invoice creation', () async {
    final clientId = await createClient();
    final inventoryItemId = await createInventoryItem(quantity: 1);

    await expectLater(
      database.createOrUpdateInvoice(
        InvoicesCompanion.insert(
          invoiceNumber: 'INV-STOCK',
          clientId: clientId,
          issueDate: now,
          dueDate: now.add(const Duration(days: 30)),
          totalAmount: 20,
          taxAmount: 0,
          subtotal: 20,
          status: 'Pending',
        ),
        [
          lineItem(inventoryItemId: inventoryItemId, quantity: 2, unitPrice: 10),
        ],
      ),
      throwsA(isA<StateError>()),
    );

    expect(await inventoryQuantity(inventoryItemId), 1);
    expect((await database.select(database.invoices).get()).length, 0);
    expect((await database.select(database.lineItems).get()).length, 0);
  });

  test('moving a payment recalculates both old and new invoices', () async {
    final clientId = await createClient();
    final firstInvoice =
        await createInvoice(clientId: clientId, invoiceNumber: 'INV-A');
    final secondInvoice =
        await createInvoice(clientId: clientId, invoiceNumber: 'INV-B');

    final paymentId = await database.insertPayment(
      PaymentsCompanion.insert(
        invoiceId: firstInvoice.id,
        amount: 100,
        date: now,
        method: 'Cash',
      ),
    );

    expect(
      (await (database.select(database.invoices)
            ..where((i) => i.id.equals(firstInvoice.id)))
          .getSingle())
          .status,
      'Paid',
    );

    await database.updatePayment(
      PaymentsCompanion.insert(
        id: Value(paymentId),
        invoiceId: secondInvoice.id,
        amount: 100,
        date: now,
        method: 'Cash',
      ),
    );

    final updatedFirst = await (database.select(database.invoices)
          ..where((i) => i.id.equals(firstInvoice.id)))
        .getSingle();
    final updatedSecond = await (database.select(database.invoices)
          ..where((i) => i.id.equals(secondInvoice.id)))
        .getSingle();

    expect(updatedFirst.status, 'Pending');
    expect(updatedSecond.status, 'Paid');
  });

  test('deleting a payment reopens a paid invoice', () async {
    final clientId = await createClient();
    final invoice = await createInvoice(clientId: clientId);
    final paymentId = await database.insertPayment(
      PaymentsCompanion.insert(
        invoiceId: invoice.id,
        amount: 100,
        date: now,
        method: 'Cash',
      ),
    );

    expect(
      (await (database.select(database.invoices)
            ..where((i) => i.id.equals(invoice.id)))
          .getSingle())
          .status,
      'Paid',
    );

    await database.deletePayment(paymentId);

    expect(
      (await (database.select(database.invoices)
            ..where((i) => i.id.equals(invoice.id)))
          .getSingle())
          .status,
      'Pending',
    );
  });

  test('client balances are derived from opening balance and invoice payments',
      () async {
    final debtorId = await createClient(openingBalance: 50);
    await createInvoice(
      clientId: debtorId,
      invoiceNumber: 'INV-DRAFT',
      status: 'Draft',
      total: 100,
    );
    final pendingInvoice = await createInvoice(
      clientId: debtorId,
      invoiceNumber: 'INV-PENDING',
      total: 200,
    );
    await database.insertPayment(
      PaymentsCompanion.insert(
        invoiceId: pendingInvoice.id,
        amount: 75,
        date: now,
        method: 'Cash',
      ),
    );

    await createClient(
      name: 'Supplier',
      type: 'Creditor',
      openingBalance: -20,
    );

    final clients = await database.getAllClientsWithBalance();
    final debtor = clients.singleWhere((c) => c.client.id == debtorId);

    expect(debtor.openingBalance, 50);
    expect(debtor.currentBalance, closeTo(175, 0.001));
    expect(await database.getTotalReceivables(), closeTo(175, 0.001));
    expect(await database.getTotalPayables(), closeTo(20, 0.001));
  });
}
