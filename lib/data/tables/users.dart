import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // This can be a username or email for the local user. Doesn't need to be globally unique.
  TextColumn get username => text()();
  
  // HASH of the local user's password.
  TextColumn get passwordHash => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}