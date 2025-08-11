import 'package:drift/drift.dart';

// Stores the application's activation status
class Licenses extends Table {
  // We only ever expect one row in this table.
  IntColumn get id => integer().withDefault(const Constant(1))();
  
  // The license key provided to the customer. We'll store it encrypted.
  TextColumn get licenseKeyEncrypted => text()();
  
  // The date the product was activated.
  DateTimeColumn get activationDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}