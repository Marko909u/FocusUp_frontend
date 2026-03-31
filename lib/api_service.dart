import 'package:dio/dio.dart';
import 'token_storage.dart'; // Importa el archivo del Paso 2

class ApiService {
  late Dio dio;

  // Cambiar esta IP por la IP local del ordenador de Javi
  // Ej: Si Javi tiene la 192.168.1.55, pon 'http://192.168.1.55:8080/api'
  // Si usáis emulador Android apuntando al mismo PC, usad 'http://10.0.2.2:8080/api'
  final String baseUrl = 'http://10.1.105.11:8080/api';

  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10), // Tiempo de espera
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    // AÑADIMOS EL INTERCEPTOR MÁGICO
    dio.interceptors.add(
      InterceptorsWrapper(
        // 1. ANTES DE ENVIAR LA PETICIÓN: Añadimos el Token
        onRequest: (options, handler) async {
          // No necesitamos token para login o registro
          if (!options.path.contains('/auth/login') && !options.path.contains('/auth/register')) {
            String? token = await TokenStorage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options); // Continúa con la petición
        },

        // 2. SI HAY UN ERROR: Manejamos si el token caduca (Error 401/403)
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            print("Token caducado o inválido. Cerrando sesión...");
            await TokenStorage.deleteToken();

            // TODO: Aquí deberías redirigir al usuario a la pantalla de Login.
            // Ej: navigatorKey.currentState?.pushReplacementNamed('/login');
          }
          return handler.next(e); // Pasa el error para manejarlo en la UI si hace falta
        },
      ),
    );
  }
}

// Creamos una instancia global (Singleton) para usarla en toda la app
final apiService = ApiService().dio;