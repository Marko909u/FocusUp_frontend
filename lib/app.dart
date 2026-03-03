import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaginaPrincipal extends StatefulWidget {
  final String nombreUsuario;

  const PaginaPrincipal({Key? key, required this.nombreUsuario}) : super(key: key);

  @override
  _PaginaPrincipalState createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int _indiceActual = 0;

  // 1. Creamos una variable para guardar el token que leeremos
  String _miToken = "Cargando token...";

  DateTime _fechaSeleccionada = DateTime.now();
  // 2. initState se ejecuta automáticamente UNA VEZ justo cuando se abre la pantalla
  @override
  void initState() {
    super.initState();
    _cargarTokenGuardado(); // Llamamos a nuestra función
  }

  // 3. Función para leer la memoria del móvil
  Future<void> _cargarTokenGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    // Leemos el token usando la misma llave 'jwt_token' que usamos en el login
    String? tokenGuardado = prefs.getString('jwt_token');

    // Actualizamos la pantalla con el token encontrado
    setState(() {
      _miToken = tokenGuardado ?? "No se encontró ningún token guardado";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FocusUp'),
        automaticallyImplyLeading: false,
      ),

      body: Center(
        // Añadimos un poco de Padding para que el token no pegue con los bordes
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¡Bienvenido, ${widget.nombreUsuario}!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 20),

              Container(
                width: 320,

                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CalendarDatePicker(
                  initialDate: _fechaSeleccionada,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (DateTime nuevaFecha) {
                    setState(() {
                      _fechaSeleccionada = nuevaFecha;
                    });
                  },
                ),
              ),
              // --- FIN DEL CALENDARIO ---

              SizedBox(height: 20),

              // (Opcional) Puedes dejar el token aquí abajo si aún lo necesitas para pruebas
              Text('Tu Token es:'),
              SelectableText(_miToken, style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementar la acción del botón
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
