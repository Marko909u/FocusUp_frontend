import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:dio/dio.dart'; // Importamos Dio
import 'api_service.dart'; // Importamos tu servicio centralizado

class Register extends StatefulWidget {
  const Register({super.key});

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

    try {
      // NUEVO: Usamos tu apiService global (que ya tiene la IP configurada)
      final response = await apiService.post(
        '/auth/register',
        data: datosRegistro,
      );

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
      if (!mounted) return;

      String mensajeError = 'Error en el registro: Verifica tus datos.';
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
          title: const Text('Registro'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Form(
                key: _formkey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TextFormField(
                        controller: controladorUsuario,
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Introduzca su nombre de usuario'),
                        ]).call,
                        decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Nombre de usuario',
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person, color: Colors.blue),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10.0, right: 5.0),
                            child: TextFormField(
                              controller: controladorNombre,
                              validator: MultiValidator([
                                RequiredValidator(errorText: 'Obligatorio'),
                              ]).call,
                              decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Nombre',
                                  labelText: 'Nombre',
                                  prefixIcon: Icon(Icons.badge, color: Colors.green),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10.0, left: 5.0),
                            child: TextFormField(
                              controller: controladorApellidos,
                              validator: MultiValidator([
                                RequiredValidator(errorText: 'Obligatorio'),
                              ]).call,
                              decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Apellidos',
                                  labelText: 'Apellidos',
                                  prefixIcon: Icon(Icons.badge_outlined, color: Colors.grey),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TextFormField(
                        controller: controladorEmail,
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Introduzca un email'),
                          EmailValidator(errorText: 'Email inválido'),
                        ]).call,
                        decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'nombre@ejemplo.com',
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: Colors.lightBlue),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: TextFormField(
                          controller: controladorFechaNacimiento,
                          readOnly: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: "Fecha de nacimiento",
                            hintText: "Selecciona una fecha",
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
                              setState(() {
                                controladorFechaNacimiento.text = "$anio-$mes-$dia";
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Campo obligatorio";
                            }
                            return null;
                          },
                        )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: TextFormField(
                        controller: controladorPassword,
                        obscureText: true,
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Introduzca una contraseña'),
                          MinLengthValidator(8,
                              errorText: 'Mínimo 8 caracteres'),
                          PatternValidator(r'[A-Z]', errorText: 'Debe contener una mayúscula'),
                          PatternValidator(r'[0-9]', errorText: 'Debe contener un número'),
                          PatternValidator(r'[$;._*]', errorText: r'Carácter especial ($;._*)'),
                        ]).call,
                        decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Cree una contraseña',
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock, color: Colors.grey),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
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
                            child: const Text(
                              'Registrarme',
                              style: TextStyle(color: Colors.white, fontSize: 20),
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
