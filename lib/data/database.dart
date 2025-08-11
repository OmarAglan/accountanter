import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users.dart';
import 'tables/licenses.dart';
import 'tables/clients.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Users, Licenses, Clients])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // We are now on version 3

  // --- THIS IS THE FIX ---
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // This is called only when the database is first created.
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // This is called when the schemaVersion is increased.
        if (from < 2) {
          // We added the licenses table in version 2
          await m.createTable(licenses);
          
          // We also modified the users table (email -> username)
          // For simplicity in development, we'll just re-create it.
          // In a real app with user data, you would carefully migrate the data.
          await m.drop(users);
          await m.createTable(users);
        }
        if (from < 3) {
          // We added the clients table in version 3
          await m.createTable(clients);
        }
      },
    );
  }
  // --- END OF FIX ---


  // --- License-related methods ---
  Future<License?> getLicense() {
    return (select(licenses)..where((l) => l.id.equals(1))).getSingleOrNull();
  }
  
  Future<void> saveLicense(LicensesCompanion license) {
    return into(licenses).insert(license, mode: InsertMode.replace);
  }

  // --- User-related methods ---
  Future<User?> getLocalUser() {
    return (select(users)).getSingleOrNull();
  }

  Future<void> createLocalUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  // --- Client-related methods ---
  Future<List<Client>> getAllClients() => select(clients).get();
  Stream<List<Client>> watchAllClients() => select(clients).watch();
  Future<int> insertClient(ClientsCompanion client) => into(clients).insert(client);
  Future<bool> updateClient(ClientsCompanion client) => update(clients).replace(client);
  Future<int> deleteClient(int id) => (delete(clients)..where((c) => c.id.equals(id))).go();
  
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