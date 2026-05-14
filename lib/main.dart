import 'package:flutter/material.dart';
import 'package:focusup/app.dart';
import 'package:focusup/login.dart';
import 'package:focusup/register.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'token_storage.dart';
import 'api_service.dart';

// Notificador global para el tema
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// Navigator Key para navegar sin contexto (ej: desde el Interceptor de Dio)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Mi App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
          ),
          themeMode: currentMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'),
          ],
          // Usamos rutas para facilitar la navegación global
          initialRoute: '/',
          routes: {
            '/': (context) => const InitialCheck(),
            '/menu': (context) => const MenuPrincipal(),
            '/login': (context) => const Login(),
          },
        );
      },
    );
  }
}

class InitialCheck extends StatefulWidget {
  const InitialCheck({super.key});

  @override
  State<InitialCheck> createState() => _InitialCheckState();
}

class _InitialCheckState extends State<InitialCheck> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await TokenStorage.getToken();
    if (token != null) {
      try {
        // Intentamos obtener los datos del usuario para validar el token
        final response = await apiService.get('/users/me');
        if (mounted && response.statusCode == 200) {
          final userData = response.data;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaginaPrincipal(
                nombreUsuario: userData['username'] ?? 'Usuario',
                correoUsuario: userData['email'] ?? '',
              ),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint("Token inválido o error de red: $e");
        await TokenStorage.deleteToken();
      }
    }
    
    // Si no hay token o falló la validación, vamos al menú principal
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'Bienvenido/a',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Por favor, selecciona una opción para continuar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Register()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Registrarse', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: Colors.blue, width: 2),
              ),
              child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
