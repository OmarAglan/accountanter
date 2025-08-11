import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users.dart';
import 'tables/licenses.dart'; // Import the new table

part 'database.g.dart';

@DriftDatabase(tables: [Users, Licenses]) // Add Licenses to the annotation
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // *** INCREMENT THE SCHEMA VERSION ***

  // --- License-related methods ---

  /// Checks if the application has a valid license.
  Future<License?> getLicense() {
    return (select(licenses)..where((l) => l.id.equals(1))).getSingleOrNull();
  }
  
  /// Saves the license key.
  Future<void> saveLicense(LicensesCompanion license) {
    return into(licenses).insert(license, mode: InsertMode.replace);
  }

  // --- User-related methods ---

  /// Gets the local user. Since it's a single-user app, we expect only one.
  Future<User?> getLocalUser() {
    return (select(users)).getSingleOrNull();
  }

  /// Creates the local user account.
  Future<void> createLocalUser(UsersCompanion user) {
    return into(users).insert(user);
  }
  
  /// Deletes all data to reset the application to a fresh state.
  Future<void> factoryReset() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'accountanter.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}