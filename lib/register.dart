import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:dio/dio.dart'; // Importamos Dio
import 'api_service.dart'; // Importamos tu servicio centralizado

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formkey = GlobalKey<FormState>();
  final controladorUsuario = TextEditingController();
  final controladorEmail = TextEditingController();
  final controladorPassword = TextEditingController();
  final controladorNombre = TextEditingController();
  final controladorApellidos = TextEditingController();
  final controladorFechaNacimiento = TextEditingController();

  // NUEVO: Variable para controlar la ruedita de carga
  bool _isLoading = false;

  Future<void> registrarUsuario() async {
    // NUEVO: Activamos la ruedita de carga
    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> datosRegistro = {
      "username": controladorUsuario.text.trim(),
      "nom": controladorNombre.text.trim(),
      "email": controladorEmail.text.trim(),
      "password": controladorPassword.text.trim(),
      "cognoms": controladorApellidos.text.trim(),
      "data_naixement": controladorFechaNacimiento.text.trim()
    };

    print("=== DATOS QUE SE VAN A ENVIAR ===");
    print(datosRegistro);
    print("=================================");

    try {
      // NUEVO: Usamos tu apiService global (que ya tiene la IP configurada)
      final response = await apiService.post(
        '/auth/register',
        data: datosRegistro,
      );

      // Si llegamos aquí, el statusCode es 200 o 201 automáticamente gracias a Dio
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

      // NUEVO: Volvemos a la pantalla de Login automáticamente
      Navigator.pop(context);

    } on DioException catch (e) {
      // NUEVO: Manejo de errores de Dio
      print("Error de conexión: ${e.response?.data}");

      if (!mounted) return;

      String mensajeError = 'Error en el registro: Verifica tus datos.';
      // Si Javier envía un mensaje de error específico, lo mostramos
      if (e.response?.data != null && e.response?.data['message'] != null) {
        mensajeError = e.response?.data['message'];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // NUEVO: Apagamos la ruedita de carga pase lo que pase
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Registro'),
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
                          height: 50, // Lo he reducido un poco para que no ocupe tanto
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextFormField(
                        controller: controladorUsuario,
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
                            errorStyle: TextStyle(fontSize: 14.0),
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
                            errorStyle: TextStyle(fontSize: 14.0),
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
                            errorStyle: TextStyle(fontSize: 14.0),
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
                          EmailValidator(errorText: 'Email invalido'),
                        ]),
                        decoration: InputDecoration(
                            hintText: 'Introduzca un email',
                            labelText: 'Email',
                            prefixIcon: Icon(
                              Icons.email,
                              color: Colors.lightBlue,
                            ),
                            errorStyle: TextStyle(fontSize: 14.0),
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
                            DateTime? fechaSeleccionada = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );

                            if (fechaSeleccionada != null) {
                              String anio = fechaSeleccionada.year.toString();
                              String mes = fechaSeleccionada.month.toString().padLeft(2, '0');
                              String dia = fechaSeleccionada.day.toString().padLeft(2, '0');

                              String fechaFormateada = "$anio-$mes-$dia";

                              setState(() {
                                controladorFechaNacimiento.text = fechaFormateada;
                              });
                            }
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
                              errorText: 'La contraseña debe ser al menos de 8 caracteres'),
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
                            errorStyle: TextStyle(fontSize: 14.0),
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
                          // NUEVO: Mostramos la ruedita si _isLoading es true
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                            onPressed: () {
                              if (_formkey.currentState!.validate()) {
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