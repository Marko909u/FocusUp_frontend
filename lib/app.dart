import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'settings.dart'; // Importamos la nueva página de configuración

class PaginaPrincipal extends StatefulWidget {
  final String nombreUsuario;  const PaginaPrincipal({Key? key, required this.nombreUsuario}) : super(key: key);

  @override
  _PaginaPrincipalState createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int _indiceActual = 0;
  String _miToken = "Cargando token...";
  String _correoUsuario = "usuario@ejemplo.com";
  DateTime _fechaSeleccionada = DateTime.now();

  final Map<DateTime, List<Map<String, dynamic>>> _recordatorios = {};

  Timer? _cronometro;
  Duration _tiempoTranscurrido = Duration.zero;
  bool _cronometroActivo = false;

  @override
  void initState() {
    super.initState();
    _cargarTokenGuardado();
  }

  DateTime _soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

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

  // --- LÓGICA DEL CALENDARIO PERSONALIZADO ---
  String _nombreMes(int mes) {
    const meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    return meses[mes - 1];
  }

  Widget _calendarioPersonalizado() {
    DateTime primerDiaMes = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, 1);
    int diasEnMes = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1,0).day;
    int desfase = primerDiaMes.weekday - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                icon: Icon(Icons.chevron_left, color: Colors.blue),
                onPressed: () => setState(() => _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month - 1, 1))
            ),
            Text(
                "${_nombreMes(_fechaSeleccionada.month)} ${_fechaSeleccionada.year}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            IconButton(
                icon: Icon(Icons.chevron_right, color: Colors.blue),
                onPressed: () => setState(() => _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 1))
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["L", "M", "X", "J", "V", "S", "D"]
              .map((d) => Text(d, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)))
              .toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: diasEnMes + desfase,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemBuilder: (context, index) {
            if (index < desfase) return SizedBox();
            int dia = index - desfase + 1;
            DateTime fechaDia = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, dia);
            bool seleccionado = _soloFecha(_fechaSeleccionada) == _soloFecha(fechaDia);
            final recs = _recordatorios[_soloFecha(fechaDia)] ?? [];

            return GestureDetector(
              onTap: () => setState(() => _fechaSeleccionada = fechaDia),
              child: Container(
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? (isDark ? Colors.blue[900]!.withOpacity(0.5) : Colors.blue[100])
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: seleccionado ? Border.all(color: Colors.blue, width: 1) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "$dia",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                            color: seleccionado ? Colors.blue : null // Resalta el día seleccionado
                        )
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: recs.take(3).map((r) => Container(
                        width: 5, height: 5, margin: EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: r['color']),
                      )).toList(),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _mostrarDialogoRecordatorio() {
    String mensaje = "";
    Color colorSeleccionado = Colors.blue;
    DateTime fechaTemp = _fechaSeleccionada;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Nuevo Recordatorio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("Fecha: ${fechaTemp.day}/${fechaTemp.month}/${fechaTemp.year}"),
                    leading: Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: fechaTemp, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (picked != null) setDialogState(() => fechaTemp = picked);
                    },
                  ),
                  TextField(decoration: InputDecoration(labelText: 'Mensaje'), onChanged: (val) => mensaje = val),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple].map((color) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => colorSeleccionado = color),
                        child: CircleAvatar(backgroundColor: color, radius: 15, child: colorSeleccionado == color ? Icon(Icons.check, size: 16, color: Colors.white) : null),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (mensaje.isNotEmpty) {
                      setState(() {
                        final f = _soloFecha(fechaTemp);
                        if (_recordatorios[f] == null) _recordatorios[f] = [];
                        _recordatorios[f]!.add({'mensaje': mensaje, 'color': colorSeleccionado});
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- MÉTODOS DE LAS OTRAS PÁGINAS (Cronómetro, Perfil, etc) ---
  void _alternarCronometro() {
    if (_cronometroActivo) {
      _cronometro?.cancel();
      setState(() => _cronometroActivo = false);
    } else {
      setState(() => _cronometroActivo = true);
      _cronometro = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() => _tiempoTranscurrido += Duration(seconds: 1));
      });
    }
  }

  void _resetearCronometro() {
    _cronometro?.cancel();
    setState(() { _tiempoTranscurrido = Duration.zero; _cronometroActivo = false; });
  }

  String _formatearTiempo(Duration duration) {
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return "${dosDigitos(duration.inHours)}:${dosDigitos(duration.inMinutes.remainder(60))}:${dosDigitos(duration.inSeconds.remainder(60))}";
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MenuPrincipal()), (route) => false);
  }

  Widget _paginaInicio() {
    final fActual = _soloFecha(_fechaSeleccionada);
    final listaHoy = _recordatorios[fActual] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
                '¡Bienvenido, ${widget.nombreUsuario}!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue[200] : Colors.blueAccent
                )
            ),
            SizedBox(height: 20),
            Container(
              width: 300,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // Se adapta al modo oscuro
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: isDark ? Colors.black54 : Colors.black12,
                      blurRadius: 10
                  )
                ],
                border: Border.all(
                    color: isDark ? Colors.blueGrey[800]! : Colors.blue[100]!
                ),
              ),
              child: _calendarioPersonalizado(),
            ),
            SizedBox(height: 20),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    "Tareas del día:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                )
            ),
            if (listaHoy.isEmpty)
              Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Ningún recordatorio", style: TextStyle(color: Colors.grey))
              ),
            ...listaHoy.map((rec) => Card(
              color: (rec['color'] as Color).withOpacity(0.15),
              elevation: 0,
              margin: EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: rec['color'], radius: 8),
                title: Text(
                    rec['mensaje'],
                    style: TextStyle(fontWeight: FontWeight.w500)
                ),
              ),
            )).toList(),
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
          Text('Cronómetro', style: TextStyle(fontSize: 24, color: Colors.blueGrey)),
          Text(_formatearTiempo(_tiempoTranscurrido), style: TextStyle(fontSize: 70, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(onPressed: _alternarCronometro, icon: Icon(_cronometroActivo ? Icons.pause : Icons.play_arrow), label: Text(_cronometroActivo ? 'Parar' : 'Iniciar'), style: ElevatedButton.styleFrom(backgroundColor: _cronometroActivo ? Colors.orange : Colors.green, foregroundColor: Colors.white)),
              SizedBox(width: 20),
              ElevatedButton.icon(onPressed: _resetearCronometro, icon: Icon(Icons.refresh), label: Text('Resetear'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paginaTienda() {
    return const Center(
      child: Text(
        'Tienda',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _paginaPerfil() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Column(
          children: [
            CircleAvatar(radius: 60, backgroundColor: Colors.blue[100], child: Icon(Icons.person, size: 80, color: Colors.blue)),
            SizedBox(height: 20),
            Text(widget.nombreUsuario, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(_correoUsuario, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 40),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.blue),
                    title: Text('Configuración'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  Divider(height: 1),
                  ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)), onTap: _cerrarSesion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FocusUp'), automaticallyImplyLeading: false),
      body: [_paginaInicio(), _paginaExplorar(), _paginaTienda(), _paginaPerfil()][_indiceActual],
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoRecordatorio,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.blue[100],
        type: BottomNavigationBarType.fixed, // Asegura que se vean todos los nombres
        currentIndex: _indiceActual,
        onTap: (index) => setState(() => _indiceActual = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Cronómetro'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Tienda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
