import 'package:drift/drift.dart';

// Defines the 'clients' table
class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  
  // 'Debtor' (owes you money) or 'Creditor' (you owe them money)
  TextColumn get type => text()(); 
  
  // The client's current balance.
  // Positive means they owe you (receivable).
  // Negative means you owe them (payable).
  RealColumn get balance => real().withDefault(const Constant(0.0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}