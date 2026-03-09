import 'dart:async';
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
  String _miToken = "Cargando token...";
  DateTime _fechaSeleccionada = DateTime.now();


  Timer? _cronometro;
  Duration _tiempoTranscurrido = Duration.zero;
  bool _cronometroActivo = false;

  @override
  void initState() {
    super.initState();
    _cargarTokenGuardado();
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    super.dispose();
  }

  Future<void> _cargarTokenGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    String? tokenGuardado = prefs.getString('jwt_token');
    setState(() {
      _miToken = tokenGuardado ?? "No se encontró ningún token guardado";
    });
  }


  void _alternarCronometro() {
    if (_cronometroActivo) {
      _cronometro?.cancel();
      setState(() {
        _cronometroActivo = false;
      });
    } else {
      setState(() {
        _cronometroActivo = true;
      });
      _cronometro = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _tiempoTranscurrido += Duration(seconds: 1);
        });
      });
    }
  }

  void _resetearCronometro() {
    _cronometro?.cancel();
    setState(() {
      _tiempoTranscurrido = Duration.zero;
      _cronometroActivo = false;
    });
  }

  String _formatearTiempo(Duration duration) {
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    final horas = dosDigitos(duration.inHours);
    final minutos = dosDigitos(duration.inMinutes.remainder(60));
    final segundos = dosDigitos(duration.inSeconds.remainder(60));
    return "$horas:$minutos:$segundos";
  }


  Widget _paginaInicio() {
    return Center(
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
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
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
            SizedBox(height: 20),
            Text('Tu Token es:'),
            SelectableText(_miToken, style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }


  Widget _paginaExplorar() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Cronómetro',
            style: TextStyle(fontSize: 24, color: Colors.blueGrey),
          ),
          SizedBox(height: 10),
          Text(
            _formatearTiempo(_tiempoTranscurrido),
            style: TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _alternarCronometro,
                icon: Icon(_cronometroActivo ? Icons.pause : Icons.play_arrow),
                label: Text(_cronometroActivo ? 'Parar' : 'Iniciar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cronometroActivo ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _resetearCronometro,
                icon: Icon(Icons.refresh),
                label: Text('Resetear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paginaPerfil() {
    return Center(
      child: Text('Perfil de Usuario', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _paginas = [
      _paginaInicio(),
      _paginaExplorar(),
      _paginaPerfil(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('FocusUp'),
        automaticallyImplyLeading: false,
      ),


      body: _paginas[_indiceActual],

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Poner acción del botón
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.blue[100],
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
