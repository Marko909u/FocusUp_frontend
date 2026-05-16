import 'package:flutter/material.dart';
import 'package:focusup/views/pagina_principal.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:dio/dio.dart';
import '../core/token_storage.dart';
import '../core/api_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Map userData = {};
  final _formkey = GlobalKey<FormState>();
  final controladorUsuario = TextEditingController();
  final controladorPassword = TextEditingController();

  Future<void> logearUsuario() async {
    try {
      final response = await apiService.post(
        '/auth/login',
        data: {
          "username": controladorUsuario.text,
          "password": controladorPassword.text,
        },
      );

      // 1. Obtenemos los datos de la respuesta
      final dynamic decodedBody = response.data;
      print("📦 Respuesta del Backend: $decodedBody");
      
      String? token;
      String email = controladorUsuario.text;

      if (decodedBody is Map) {
        token = decodedBody['token']?.toString();
        if (decodedBody.containsKey('email')) {
          email = decodedBody['email'];
        }
      } else {
        token = decodedBody.toString();
      }

      print(" Token extraído: $token");

      if (token == null || token.isEmpty || token == "null") {
        print(" ERROR: El token recibido es nulo o inválido");
        throw Exception("Token no encontrado en la respuesta");
      }

      // 3. Guardamos el token
      await TokenStorage.saveToken(token);

      print("¡Login exitoso! Token guardado.");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaginaPrincipal(
              nombreUsuario: controladorUsuario.text,
              correoUsuario: email,
            ),
          ),
        );
      }
    } on DioException catch (e) {
      print("Error en el login (Status ${e.response?.statusCode}): ${e.response?.data}");
      if (mounted) {
        String errorMsg = "Usuario o contraseña incorrectos";
        if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
          errorMsg = e.response?.data['message'] ?? errorMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      print("Error inesperado: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: controladorUsuario,
                    keyboardType: TextInputType.emailAddress,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Introduzca su nombre de usuario o correo'),
                      MinLengthValidator(3,
                          errorText: 'El nombre debe tener al menos 3 caracteres'),
                    ]).call,
                    decoration: const InputDecoration(
                      hintText: 'Introduzca su correo electrónico',
                      labelText: 'Usuario / Email',
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.blue,
                      ),
                      errorStyle: TextStyle(fontSize: 18.0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.all(Radius.circular(9.0)),
                      ),
                    ),
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: controladorPassword,
                    obscureText: true,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Introduzca una contraseña'),
                      MinLengthValidator(3, errorText: 'La contraseña debe tener al menos 3 caracteres'),
                    ]).call,
                    decoration: const InputDecoration(
                      hintText: 'Introduzca su contraseña',
                      labelText: 'Contraseña',
                      prefixIcon: Icon(
                        Icons.password,
                        color: Colors.grey,
                      ),
                      errorStyle: TextStyle(fontSize: 18.0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.all(Radius.circular(9.0)),
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formkey.currentState!.validate()) {
                            print('Login form submitted');
                            logearUsuario();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
