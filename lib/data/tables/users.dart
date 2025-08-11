import 'package:drift/drift.dart';

// Defines the 'users' table in the database.
class Users extends Table {
  // Primary key, auto-incrementing integer
  IntColumn get id => integer().autoIncrement()();
  
  // User's email, must be unique
  TextColumn get email => text().unique()();
  
  // We store a HASH of the password, never the password itself.
  TextColumn get passwordHash => text()();

  // Timestamp for when the user was created
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}