import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:drift/drift.dart';

import '../../data/database.dart';
import '../../services/secure_storage_service.dart';

class AuthService extends ChangeNotifier {
  final database = AppDatabase.instance;
  final _secureStorage = SecureStorageService();

  AuthService();

  // --- Private Helper Methods ---
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // In a real app, this would check against a server or use public/private key crypto.
  // For this local app, we'll just check if the key is a specific value.
  bool _isLicenseKeySyntaxValid(String key) {
    // Example: A valid key is "TEST-LICENSE-KEY"
    return key == "TEST-LICENSE-KEY";
  }

  // --- Public API ---

  Future<bool> isAppActivated() async {
    final license = await database.getLicense();
    return license != null;
  }
  
  Future<bool> validateAndSaveLicense(String licenseKey) async {
    if (!_isLicenseKeySyntaxValid(licenseKey)) {
      return false;
    }

    final newLicense = LicensesCompanion(
      licenseKeyEncrypted: Value(licenseKey), // In a real app, encrypt this!
      activationDate: Value(DateTime.now()),
    );
    await database.saveLicense(newLicense);
    return true;
  }

  Future<void> createLocalUser(String username, String password) async {
    final newUser = UsersCompanion(
      username: Value(username),
      passwordHash: Value(_hashPassword(password)),
    );
    await database.createLocalUser(newUser);
  }

  Future<bool> login(String username, String password, bool rememberMe) async {
    final user = await database.getLocalUser();
    if (user == null) return false;

    if (user.username == username && user.passwordHash == _hashPassword(password)) {
      if (rememberMe) {
        await _secureStorage.saveRememberMeToken(username);
      }
      return true;
    }
    return false;
  }
  
  Future<String?> getLoggedInUser() async {
    return _secureStorage.getRememberMeToken();
  }

  Future<void> logout() async {
    await _secureStorage.deleteRememberMeToken();
  }

  Future<void> factoryReset() async {
    await database.factoryReset();
    await _secureStorage.deleteRememberMeToken();
  }
}