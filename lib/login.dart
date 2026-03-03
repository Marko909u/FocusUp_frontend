import 'package:flutter/material.dart';
import 'package:focusup/app.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Map userData = {};
  final _formkey = GlobalKey<FormState>();
  final controladorUsuario = TextEditingController();
  final controladorPassword = TextEditingController();

  Future<void> logearUsuario() async {
    final url = Uri.parse('http://10.1.105.25:8080/api/auth/login');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": controladorUsuario.text,
        "password": controladorPassword.text,
      }),
    );

    if (response.statusCode == 200) {
      // 1. El token es directamente el cuerpo de la respuesta
      final String token = response.body;

      // 2. Lo guardamos en la memoria del teléfono
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);

      print("¡Login exitoso! Redirigiendo a la pantalla principal...");

      // 3. Navegamos a la PaginaPrincipal y evitamos que el usuario pueda volver atrás al Login
      if (mounted) { // Buena práctica en Flutter antes de navegar tras un 'await'
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaginaPrincipal(
              // Le pasamos el nombre que el usuario escribió en el TextField
              nombreUsuario: controladorUsuario.text,
            ),
          ),
        );
      }
    } else {
      print("Credenciales incorrectas (Error ${response.statusCode})");
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
                // Espaciador superior o logo
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 150,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: controladorUsuario,
                    keyboardType: TextInputType.emailAddress,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Introduzca su nombre de usuario'),
                      MinLengthValidator(3,
                          errorText: 'Minimum 3 charecter filled name'),
                    ]),
                    decoration: const InputDecoration(
                      hintText: 'Introduzca su nombre de usuario',
                      labelText: 'Usuario',
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
                    ]),
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
                            // poner lógica de autenticación
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