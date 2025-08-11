import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _keyRememberMe = 'remember_me_token';

  Future<void> saveRememberMeToken(String username) async {
    await _storage.write(key: _keyRememberMe, value: username);
  }

  Future<String?> getRememberMeToken() async {
    return await _storage.read(key: _keyRememberMe);
  }

  Future<void> deleteRememberMeToken() async {
    await _storage.delete(key: _keyRememberMe);
  }
}