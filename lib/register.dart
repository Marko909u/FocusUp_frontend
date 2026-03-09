import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  Map userData = {};
  final _formkey = GlobalKey<FormState>();
  final controladorUsuario = TextEditingController();
  final controladorEmail = TextEditingController();
  final controladorPassword = TextEditingController();
  final controladorNombre = TextEditingController();
  final controladorApellidos = TextEditingController();
  final controladorFechaNacimiento = TextEditingController();



  Future<void> registrarUsuario() async {
    final url = Uri.parse('http://10.1.105.25:8080/api/auth/register');

    // 1. Agrupamos todos los datos en un Mapa (diccionario)
    final Map<String, dynamic> datosRegistro = {
      "username": controladorUsuario.text,
      "nom": controladorNombre.text,
      "email": controladorEmail.text,
      "password": controladorPassword.text,
      "cognoms": controladorApellidos.text,
      "data_naixement": controladorFechaNacimiento.text
    };

    // 2. ¡Printeamos los datos en la consola!
    print("=== DATOS QUE SE VAN A ENVIAR ===");
    // Usamos jsonEncode aquí también para verlo exactamente con el formato
    // que le llegará al Spring Boot de tu compañero
    print(jsonEncode(datosRegistro));
    print("=================================");

    try {
      // 3. Enviamos la petición usando la variable que creamos arriba
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(datosRegistro), // Queda mucho más limpio así
      );



      if (response.statusCode == 200 || response.statusCode == 201) {
        print("¡Registro exitoso en consola!");


        if (!mounted) return;


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Registro exitoso! Ya puedes iniciar sesión.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );



      } else {

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el registro: Verifica tus datos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error de conexión: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('registro'),
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
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 150,
                          //decoration: BoxDecoration(
                          //borderRadius: BorderRadius.circular(40),
                          //border: Border.all(color: Colors.blueGrey)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextFormField(
                          controller: controladorUsuario,
                        // validator: ((value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'please enter some text';
                        //   } else if (value.length < 5) {
                        //     return 'Enter atleast 5 Charecter';
                        //   }

                        //   return null;
                        // }),
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Introduzca su nombre de usuario'),
                        ]),

                        decoration: InputDecoration(
                            hintText: 'Introduzca su nombre de usuario',
                            labelText: 'Usuario',
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.blue,
                            ),
                            errorStyle: TextStyle(fontSize: 18.0),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                                borderRadius:
                                BorderRadius.all(Radius.circular(9.0)))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextFormField(
                        controller: controladorNombre,
                        // validator: ((value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'please enter some text';
                        //   } else if (value.length < 5) {
                        //     return 'Enter atleast 5 Charecter';
                        //   }

                        //   return null;
                        // }),
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Introduzca su nombre'),
                        ]),

                        decoration: InputDecoration(
                            hintText: 'Introduzca su nombre',
                            labelText: 'Nombre',
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.green,
                            ),
                            errorStyle: TextStyle(fontSize: 18.0),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                                borderRadius:
                                BorderRadius.all(Radius.circular(9.0)))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: controladorApellidos,
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Introduzca sus apellidos'),
                        ]),
                        decoration: InputDecoration(
                            hintText: 'Introduzca sus apellidos',
                            labelText: 'Apellidos',
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                            errorStyle: TextStyle(fontSize: 18.0),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                                borderRadius:
                                BorderRadius.all(Radius.circular(9.0)))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: controladorEmail,
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Introduzca un email'),
                          EmailValidator(
                              errorText: 'Email invalido'),
                        ]),
                        decoration: InputDecoration(
                            hintText: 'Introduzca un email',
                            labelText: 'Email',
                            prefixIcon: Icon(
                              Icons.email,
                              color: Colors.lightBlue,
                            ),
                            errorStyle: TextStyle(fontSize: 18.0),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                                borderRadius:
                                BorderRadius.all(Radius.circular(9.0)))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: controladorFechaNacimiento,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Fecha de nacimiento",
                          hintText: "Selecciona una fecha",
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());

                          // Abre el calendario de Flutter
                          DateTime? fechaSeleccionada = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000), // Fecha que se muestra al abrir (ej. año 2000)
                            firstDate: DateTime(1900),   // Nadie nació antes de 1900
                            lastDate: DateTime.now(),    // No pueden nacer en el futuro
                          );

                          // Si el usuario seleccionó una fecha y no le dio a "Cancelar"
                          // Formateamos la fecha exactamente como la quiere Spring Boot: YYYY-MM-DD
                          String anio = fechaSeleccionada!.year.toString();
                          String mes = fechaSeleccionada.month.toString().padLeft(2, '0');
                          String dia = fechaSeleccionada.day.toString().padLeft(2, '0');

                          String fechaFormateada = "$anio-$mes-$dia";

                          // Actualizamos el campo de texto para que el usuario vea la fecha
                          setState(() {
                            controladorFechaNacimiento.text = fechaFormateada;
                          });
                                                },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "La fecha de nacimiento es obligatoria";
                          }
                          return null;
                        },
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: controladorPassword,
                        obscureText: true,
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Introduzca una contraseña'),
                          MinLengthValidator(8,
                              errorText:
                              'La contraseña debe ser almenos de 8 caracteres'),
                          PatternValidator(r'[A-Z]', errorText: 'Debe contener al menos una mayúscula'),
                          PatternValidator(r'[0-9]', errorText: 'Debe contener al menos un numero'),
                          PatternValidator(r'[$;._*]', errorText: 'Debe contener un carácter especial (;._*)'),
                        ]),
                        decoration: InputDecoration(
                            hintText: 'Introduzca una contraseña',
                            labelText: 'Contraseña',
                            prefixIcon: Icon(
                              Icons.password,
                              color: Colors.grey,
                            ),
                            errorStyle: TextStyle(fontSize: 18.0),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                                borderRadius:
                                BorderRadius.all(Radius.circular(9.0)))),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formkey.currentState!.validate()) {
                                print('form submitted');
                                registrarUsuario();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Registrarme',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
          ),
        ));
  }
}