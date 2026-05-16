import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  // Guardar el token (cuando el Login sea exitoso)
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Leer el token (lo usará nuestro Interceptor)
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Borrar el token (para cerrar sesión)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}