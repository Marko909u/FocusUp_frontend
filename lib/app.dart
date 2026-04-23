import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'settings.dart'; 
import 'api_service.dart';
import 'token_storage.dart';

class PaginaPrincipal extends StatefulWidget {
  final String nombreUsuario;
  final String correoUsuario;

  const PaginaPrincipal({
    Key? key, 
    required this.nombreUsuario,
    required this.correoUsuario,
  }) : super(key: key);
  
  @override
  _PaginaPrincipalState createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> with SingleTickerProviderStateMixin {
  int _indiceActual = 0;
  String _miToken = "Cargando token...";
  late String _correoUsuario;
  String _nombreReal = "";
  String _apellidosReal = "";
  DateTime _fechaSeleccionada = DateTime.now();
  int _puntosUsuario = 0;
  int _rachaActual = 0;
  int? _selectedRecordatoriId; // Tarea seleccionada para el cronómetro
  List<dynamic> _itemsTienda = [];

  final Map<DateTime, List<Map<String, dynamic>>> _recordatorios = {};

  Timer? _cronometro;
  Duration _tiempoTranscurrido = Duration.zero;
  bool _cronometroActivo = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _correoUsuario = widget.correoUsuario;
    _cargarTokenGuardado();
    _cargarRecordatoriosDesdeBackend(); 
    _cargarNotasDesdeBackend();
    _cargarDatosUsuarioYTienda();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> _cargarDatosUsuarioYTienda() async {
    try {
      final responseItems = await apiService.get('/botiga');
      final responseUser = await apiService.get('/users/me');

      setState(() {
        _itemsTienda = responseItems.data;
        _puntosUsuario = responseUser.data['punts'] ?? 0;
        _correoUsuario = responseUser.data['email'] ?? widget.correoUsuario;
        _nombreReal = responseUser.data['nom'] ?? widget.nombreUsuario;
        _apellidosReal = responseUser.data['cognoms'] ?? "";
        _rachaActual = responseUser.data['racha'] ?? 0;
      });
    } catch (e) {
      print("Error al cargar datos del usuario: $e");
    }
  }

  Future<void> _cargarNotasDesdeBackend() async {
    try {
      final response = await apiService.get('/notas');
      if (response.statusCode == 200) {
        final List<dynamic> listaServidor = response.data;
        setState(() {
          for (var item in listaServidor) {
            DateTime fecha = _soloFecha(DateTime.parse(item['data']));
            if (_recordatorios[fecha] == null) _recordatorios[fecha] = [];
            _recordatorios[fecha]!.add({
              'id': item['id'],
              'mensaje': item['titol'],
              'contenido': item['contingut'],
              'tipo': 'nota',
              'color': Colors.orange, 
              'completada': false,
            });
          }
        });
      }
    } catch (e) {
      print("Error al obtener notas: $e");
    }
  }

  Future<void> _comprarItem(int itemId) async {
    try {
      final response = await apiService.post('/botiga/comprar/$itemId');

      if (response.statusCode == 200) {
        int nuevoSaldo = response.data['nouSaldo'];
        String mensaje = response.data['mensaje'];

        setState(() {
          _puntosUsuario = nuevoSaldo;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
        );
      }
    } on DioException catch (e) {
      String mensajeError = "Error en la compra";
      if (e.response != null && e.response?.statusCode == 400) {
        mensajeError = e.response?.data['error'] ?? "Puntos insuficientes o item ya comprado";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cargarRecordatoriosDesdeBackend() async {
    try {
      final response = await apiService.get('/recordatoris');

      if (response.statusCode == 200) {
        final List<dynamic> listaServidor = response.data;

        setState(() {
          _recordatorios.clear(); 
          for (var item in listaServidor) {
            DateTime fechaCompleta = DateTime.parse(item['dataHora']);
            DateTime fecha = _soloFecha(fechaCompleta);

            if (_recordatorios[fecha] == null) _recordatorios[fecha] = [];

            _recordatorios[fecha]!.add({
              'id': item['id'], 
              'mensaje': item['missatge'],
              'tipo': 'tarea',  
              'color': Colors.blue,   
              'completada': item['completat'] ?? false, 
              'dataHoraOriginal': item['dataHora'], 
            });
          }
        });
      }
    } catch (e) {
      print("Error al obtener recordatorios: $e");
    }
  }

  Future<void> _actualizarEstadoEnBackend(Map<String, dynamic> rec, bool nuevoEstado) async {
    final id = rec['id'];
    if (id == null) {
      setState(() => rec['completada'] = nuevoEstado);
      return;
    }

    try {
      await apiService.patch('/recordatoris/$id/estat', data: {
        "completat": nuevoEstado,
      });

      setState(() {
        rec['completada'] = nuevoEstado;
      });
    } catch (e) {
      print("Error al actualizar estado: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo sincronizar el estado")),
      );
    }
  }

  DateTime _soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  @override
  void dispose() {
    _cronometro?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarTokenGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    String? tokenGuardado = prefs.getString('jwt_token');
    setState(() {
      _miToken = tokenGuardado ?? "No se encontró ningún token";
    });
  }

  Future<dynamic> _guardarEnBackend(String tipo, String mensaje, DateTime fecha, {String? contenido}) async {
    String fechaSimple = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    String fechaISO = "${fechaSimple}T00:00:00";
    
    String endpoint = tipo == 'nota' ? '/notas' : '/recordatoris';

    Map<String, dynamic> datos;
    if (tipo == 'nota') {
      datos = {
        "titol": mensaje,
        "contingut": contenido ?? "",
        "data": fechaSimple, 
      };
    } else {
      datos = {
        "missatge": mensaje,
        "dataHora": fechaISO,
      };
    }

    try {
      final response = await apiService.post(endpoint, data: datos);
      return response.data;
    } on DioException catch (e) {
      print("Error guardando $tipo: ${e.response?.data}");
      return null;
    }
  }

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
                icon: const Icon(Icons.chevron_left, color: Colors.blue),
                onPressed: () => setState(() => _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month - 1, 1))
            ),
            Text(
                "${_nombreMes(_fechaSeleccionada.month)} ${_fechaSeleccionada.year}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.blue),
                onPressed: () => setState(() => _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 1))
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["L", "M", "X", "J", "V", "S", "D"]
              .map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)))
              .toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: diasEnMes + desfase,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemBuilder: (context, index) {
            if (index < desfase) return const SizedBox();
            int dia = index - desfase + 1;
            DateTime fechaDia = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, dia);
            bool seleccionado = _soloFecha(_fechaSeleccionada) == _soloFecha(fechaDia);
            final recs = _recordatorios[_soloFecha(fechaDia)] ?? [];

            return GestureDetector(
              onTap: () => setState(() => _fechaSeleccionada = fechaDia),
              child: Container(
                margin: const EdgeInsets.all(2),
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
                            color: seleccionado ? Colors.blue : null
                        )
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: recs.take(3).map((r) {
                        bool esTarea = r['tipo'] == 'tarea';
                        return Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            shape: esTarea ? BoxShape.rectangle : BoxShape.circle,
                            color: r['color'],
                            borderRadius: esTarea ? BorderRadius.circular(1) : null,
                          ),
                        );
                      }).toList(),
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

  void _mostrarOpcionesFab() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.note_add, color: Colors.orange),
                title: const Text('Nueva Nota'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoFormulario('nota');
                },
              ),
              ListTile(
                leading: const Icon(Icons.task_alt, color: Colors.green),
                title: const Text('Nuevo Recordatorio'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoFormulario('tarea');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoFormulario(String tipo) {
    String titulo = "";
    String contenido = "";
    String mensaje = ""; 
    Color colorSeleccionado = Colors.blue;
    DateTime fechaTemp = _fechaSeleccionada;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tipo == 'nota' ? 'Nueva Nota' : 'Nuevo Recordatorio'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text("Fecha: ${fechaTemp.day}/${fechaTemp.month}/${fechaTemp.year}"),
                      leading: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: fechaTemp, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (picked != null) setDialogState(() => fechaTemp = picked);
                      },
                    ),
                    if (tipo == 'nota') ...[
                      TextField(decoration: const InputDecoration(labelText: 'Título'), onChanged: (val) => titulo = val),
                      TextField(decoration: const InputDecoration(labelText: 'Contenido'), maxLines: 3, onChanged: (val) => contenido = val),
                    ] else ...[
                      TextField(decoration: const InputDecoration(labelText: 'Mensaje del recordatorio'), onChanged: (val) => mensaje = val),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple].map((color) {
                        return GestureDetector(
                          onTap: () => setDialogState(() => colorSeleccionado = color),
                          child: CircleAvatar(backgroundColor: color, radius: 15, child: colorSeleccionado == color ? const Icon(Icons.check, size: 16, color: Colors.white) : null),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (tipo == 'nota' ? (titulo.isNotEmpty) : (mensaje.isNotEmpty)) {
                      final resultado = await _guardarEnBackend(tipo, tipo == 'nota' ? titulo : mensaje, fechaTemp, contenido: contenido);
                      if (resultado != null) {
                        setState(() {
                          final f = _soloFecha(fechaTemp);
                          if (_recordatorios[f] == null) _recordatorios[f] = [];
                          final bool esMap = resultado is Map;
                          _recordatorios[f]!.add({
                            'id': esMap ? resultado['id'] : null,
                            'mensaje': tipo == 'nota' ? titulo : mensaje,
                            'contenido': contenido,
                            'color': colorSeleccionado,
                            'tipo': tipo,
                            'completada': false,
                            'dataHoraOriginal': esMap ? (resultado['dataHora'] ?? resultado['data']) : null,
                          });
                        });
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarDeshacerTarea(Map<String, dynamic> tarea) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deshacer tarea"),
        content: const Text("¿Deseas deshacer la tarea completada?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              setState(() => tarea['completada'] = false);
              Navigator.pop(context);
            },
            child: const Text("Sí, deshacer"),
          ),
        ],
      ),
    );
  }

  void _alternarCronometro() {
    if (_cronometroActivo) {
      _cronometro?.cancel();
      _animationController.stop();
      setState(() => _cronometroActivo = false);
    } else {
      setState(() => _cronometroActivo = true);
      _animationController.repeat();
      _cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _tiempoTranscurrido += const Duration(seconds: 1));
      });
    }
  }

  void _resetearCronometro() {
    _cronometro?.cancel();
    _animationController.stop();
    _animationController.value = 0;
    setState(() {
      _tiempoTranscurrido = Duration.zero;
      _cronometroActivo = false;
      _selectedRecordatoriId = null; // Limpiamos selección al resetear
    });
  }

  Future<void> _guardarSesionEnBackend() async {
    int minutos = _tiempoTranscurrido.inMinutes;
    if (minutos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mínimo 1 minuto")));
      return;
    }

    try {
      final data = {
        "minuts": minutos,
        if (_selectedRecordatoriId != null) "recordatoriId": _selectedRecordatoriId,
      };

      final response = await apiService.post('/sessions', data: data);
      
      if (response.statusCode == 200) {
        final puntosGanados = response.data['puntosGanados'] ?? 0;
        final nuevoSaldo = response.data['nuevoSaldo'] ?? _puntosUsuario;

        setState(() {
          _puntosUsuario = nuevoSaldo;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Éxito! Ganaste $puntosGanados puntos. Nuevo saldo: $nuevoSaldo"),
            backgroundColor: Colors.green,
          ),
        );
        
        _resetearCronometro();
        _cargarRecordatoriosDesdeBackend(); // Refrescamos por si se completó la tarea
        _cargarDatosUsuarioYTienda(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  String _formatearTiempo(Duration duration) {
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return "${dosDigitos(duration.inHours)}:${dosDigitos(duration.inMinutes.remainder(60))}:${dosDigitos(duration.inSeconds.remainder(60))}";
  }

  Future<void> _cerrarSesion() async {
    await TokenStorage.deleteToken();
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
            Text('¡Bienvenido/a, ${_nombreReal.isNotEmpty ? _nombreReal : widget.nombreUsuario}!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.blue[200] : Colors.blueAccent)),
            const SizedBox(height: 20),
            Container(
              width: 300,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black12, blurRadius: 10)],
                border: Border.all(color: isDark ? Colors.blueGrey[800]! : Colors.blue[100]!),
              ),
              child: _calendarioPersonalizado(),
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Tareas del día:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            if (listaHoy.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text("Ningún recordatorio", style: TextStyle(color: Colors.grey))),
            ...listaHoy.map((rec) => Card(
              color: (rec['color'] as Color).withOpacity(0.15),
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: rec['color'], 
                  radius: 8, 
                  child: rec['tipo'] == 'tarea' ? Container(width: 8, height: 8, decoration: BoxDecoration(color: rec['color'])) : null
                ),
                title: Text(
                  rec['mensaje'], 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    decoration: (rec['completada'] ?? false) ? TextDecoration.lineThrough : null,
                    color: (rec['completada'] ?? false) ? Colors.grey : null
                  )
                ),
                subtitle: rec['tipo'] == 'nota' && rec['contenido'] != null ? Text(rec['contenido']) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (rec['tipo'] == 'tarea')
                      Checkbox(
                        value: rec['completada'] ?? false,
                        onChanged: (rec['completada'] ?? false) 
                          ? null 
                          : (bool? value) {
                            if (value != null && value == true) {
                              _actualizarEstadoEnBackend(rec, true);
                            }
                          },
                      ),
                    Text(
                      rec['tipo'] == 'tarea' ? 'Recordatorio' : 'Nota', 
                      style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)
                    ),
                  ],
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _paginaExplorar() {
    // Obtenemos todas las tareas activas para el Dropdown
    final todasLasTareas = _recordatorios.values
        .expand((lista) => lista)
        .where((r) => r['tipo'] == 'tarea' && (r['completada'] == false))
        .toList();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Cronómetro', style: TextStyle(fontSize: 24, color: Colors.blueGrey)),
          const SizedBox(height: 20),

          // Selector de tarea (Dropdown)
          if (!_cronometroActivo) ...[
            const Text("Trabajar en:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: _selectedRecordatoriId,
              hint: const Text("Selecciona una tarea (opcional)"),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedRecordatoriId = newValue;
                });
              },
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text("Sin tarea asignada"),
                ),
                ...todasLasTareas.map((tarea) {
                  return DropdownMenuItem<int>(
                    value: tarea['id'],
                    child: Text(tarea['mensaje']),
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 20),
          ] else if (_selectedRecordatoriId != null) ...[
            // Si el cronómetro está activo, mostramos el nombre de la tarea seleccionada
            Text(
              "Tarea actual: ${todasLasTareas.firstWhere((t) => t['id'] == _selectedRecordatoriId, orElse: () => {'mensaje': '...' })['mensaje']}",
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
            ),
            const SizedBox(height: 20),
          ],

          Text(_formatearTiempo(_tiempoTranscurrido), style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          Container(
            height: 40, width: 200, margin: const EdgeInsets.symmetric(vertical: 10),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) => CustomPaint(painter: WavePainter(_animationController.value, _cronometroActivo)),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _alternarCronometro, 
                icon: Icon(_cronometroActivo ? Icons.pause : Icons.play_arrow), 
                label: Text(_cronometroActivo ? 'Parar' : 'Iniciar'), 
                style: ElevatedButton.styleFrom(backgroundColor: _cronometroActivo ? Colors.orange : Colors.green, foregroundColor: Colors.white)
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _guardarSesionEnBackend, 
                icon: const Icon(Icons.save), 
                label: const Text('Finalizar'), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white)
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _resetearCronometro, 
                icon: const Icon(Icons.refresh), 
                label: const Text('Reset'), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paginaTienda() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue[800]!]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tus Puntos:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text("$_puntosUsuario", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _itemsTienda.isEmpty 
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _itemsTienda.length,
                itemBuilder: (context, index) {
                  final item = _itemsTienda[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.redeem, size: 50, color: Colors.blue),
                        const SizedBox(height: 10),
                        Text(item['nom'] ?? 'Objeto', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("${item['preu']} pts", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _comprarItem(item['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Comprar"),
                        )
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _paginaPerfil() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 60, backgroundColor: Colors.blue, child: Icon(Icons.person, size: 80, color: Colors.white)),
            const SizedBox(height: 20),
            Text("$_nombreReal $_apellidosReal".trim().isNotEmpty ? "$_nombreReal $_apellidosReal" : widget.nombreUsuario, 
                 style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(_correoUsuario, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.settings, color: Colors.blue), title: const Text('Configuración'), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()))),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Cerrar Sesión'), onTap: _cerrarSesion),
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
      appBar: AppBar(
        title: const Text('FocusUp'),
        automaticallyImplyLeading: false,
        actions: [
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text('$_puntosUsuario', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              const Icon(Icons.whatshot, color: Colors.orange),
              const SizedBox(width: 4),
              Text('$_rachaActual', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: [_paginaInicio(), _paginaExplorar(), _paginaTienda(), _paginaPerfil()][_indiceActual],
      floatingActionButton: FloatingActionButton(onPressed: _mostrarOpcionesFab, child: const Icon(Icons.add), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue, selectedItemColor: Colors.white, unselectedItemColor: Colors.blue[100], type: BottomNavigationBarType.fixed,
        currentIndex: _indiceActual, onTap: (index) => setState(() => _indiceActual = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reloj'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Tienda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress; final bool activo; WavePainter(this.progress, this.activo);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path(); final width = size.width; final midHeight = size.height / 2;
    path.moveTo(0, midHeight);
    if (activo) {
      for (double i = 0; i <= width; i++) {
        final y = midHeight + math.sin((i / width * 2 * math.pi * 3) + (progress * 2 * math.pi)) * 10;
        path.lineTo(i, y);
      }
    } else { path.lineTo(width, midHeight); }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.activo != activo;
}
