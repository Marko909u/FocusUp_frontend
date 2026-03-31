// dio_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Dio createDio() {
  final dio = Dio();
  final storage = FlutterSecureStorage();

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Intentamos leer el token guardado en el login
      String? token = await storage.read(key: 'jwt_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    // También puedes manejar errores 403 (Token caducado) aquí para forzar el logout
  ));

  return dio;
}