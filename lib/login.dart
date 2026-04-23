import 'package:flutter/material.dart';
import 'package:focusup/app.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'token_storage.dart'; // <--- AÑADE ESTO

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
    final url = Uri.parse('https://backend-focusup.onrender.com/api/auth/login');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": controladorUsuario.text,
        "password": controladorPassword.text,
      }),
    );

    if (response.statusCode == 200) {
      // 1. Decodificamos el cuerpo de la respuesta
      final dynamic decodedBody = jsonDecode(response.body);
      String token;
      String email = controladorUsuario.text; // Valor por defecto (el username suele ser el email)

      // 2. Si es un mapa (JSON), buscamos la clave 'token' y 'email' si existe
      if (decodedBody is Map) {
        token = decodedBody['token'] ?? response.body;
        if (decodedBody.containsKey('email')) {
          email = decodedBody['email'];
        }
      } else {
        token = decodedBody.toString();
      }

      // 3. Guardamos el token ya limpio
      await TokenStorage.saveToken(token);

      print("¡Login exitoso! Token limpio guardado.");


      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaginaPrincipal(
              nombreUsuario: controladorUsuario.text,
              correoUsuario: email, // <--- Corregido: pasamos el correo
            ),
          ),
        );
      }
    } else {
      print("Credenciales incorrectas (Error ${response.statusCode})");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario o contraseña incorrectos")),
        );
      }
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
                    child: Container(
                      width: 200,
                      height: 150,
                      child: const Icon(Icons.lock_person, size: 100, color: Colors.blue),
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
                    ]),
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
