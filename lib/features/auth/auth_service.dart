import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:drift/drift.dart';

import '../../data/database.dart';

// Enum to represent the result of an authentication attempt
enum AuthResult { success, userNotFound, wrongPassword, userExists, failure }

class AuthService extends ChangeNotifier {
  final AppDatabase _database;

  AuthService(this._database);

  // --- Private Helper Methods ---
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // --- Public API ---

  /// Attempts to log in a user with the given email and password.
  Future<AuthResult> login(String email, String password) async {
    try {
      final user = await _database.getUserByEmail(email);
      if (user == null) {
        return AuthResult.userNotFound;
      }
      if (user.passwordHash != _hashPassword(password)) {
        return AuthResult.wrongPassword;
      }
      // In a real app, you would store the user session here.
      return AuthResult.success;
    } catch (e) {
      debugPrint('Login Error: $e');
      return AuthResult.failure;
    }
  }

  /// Registers a new user.
  Future<AuthResult> register(String email, String password) async {
    try {
      final existingUser = await _database.getUserByEmail(email);
      if (existingUser != null) {
        return AuthResult.userExists;
      }

      final newUser = UsersCompanion(
        email: Value(email),
        passwordHash: Value(_hashPassword(password)),
      );
      
      await _database.insertUser(newUser);
      return AuthResult.success;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return AuthResult.failure;
    }
  }

  /// Updates the password for a given user.
  /// This simulates the "forgot password" flow.
  Future<AuthResult> resetPassword(String email, String newPassword) async {
     try {
      final user = await _database.getUserByEmail(email);
      if (user == null) {
        return AuthResult.userNotFound;
      }

      final newHashedPassword = _hashPassword(newPassword);
      
      // Drift's update method
      final updated = user.copyWith(passwordHash: newHashedPassword);
      await (_database.update(_database.users)..replace(updated));

      return AuthResult.success;
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      return AuthResult.failure;
    }
  }
}