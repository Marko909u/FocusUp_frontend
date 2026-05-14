import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'settings.dart'; 
import 'api_service.dart';
import 'token_storage.dart';
import 'group_widgets.dart';

class PaginaPrincipal extends StatefulWidget {
  final String nombreUsuario;
  final String correoUsuario;

  const PaginaPrincipal({
    super.key, 
    required this.nombreUsuario,
    required this.correoUsuario,
  });
  
  @override
  _PaginaPrincipalState createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> with SingleTickerProviderStateMixin {
  int _indiceActual = 0;
  late String _correoUsuario;
  String _nombreReal = "";
  String _apellidosReal = "";
  DateTime _fechaSeleccionada = DateTime.now();
  int _puntosUsuario = 0;
  int _rachaActual = 0;
  int? _selectedRecordatoriId; 
  List<dynamic> _itemsTienda = [];
  List<dynamic> _grupos = [];

  // Contexto de Grupo
  Map<String, dynamic>? _grupoSeleccionado;
  final Map<DateTime, List<Map<String, dynamic>>> _recordatoriosGrupo = {};
  final Map<DateTime, List<Map<String, dynamic>>> _recordatorios = {};

  // Variables para el modo Reloj y Técnicas
  bool _esTemporizador = false;
  int _tecnicaSeleccionada = 0; // 0: Ninguna, 1: Pomodoro, 2: Personalizada, 3: Flowtime
  bool _estaEnFaseEstudio = true;
  int _tempHoras = 0;
  int _tempMinutos = 25;
  int _estudioPersonalizado = 25;
  int _descansoPersonalizado = 5;
  Duration _tiempoRestante = Duration.zero;
  Duration _tiempoDescansoLibre = Duration.zero;

  Timer? _cronometro;
  Duration _tiempoTranscurrido = Duration.zero;
  bool _cronometroActivo = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _correoUsuario = widget.correoUsuario;
    _cargarRecordatoriosDesdeBackend(); 
    _cargarNotasDesdeBackend();
    _cargarDatosUsuarioYTienda();
    _cargarGruposDesdeBackend();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> _cargarGruposDesdeBackend() async {
    try {
      final response = await apiService.get('/grups/me');
      if (mounted) setState(() { _grupos = response.data; });
    } catch (e) { debugPrint("Error grupos: $e"); }
  }

  Future<void> _seleccionarGrupo(Map<String, dynamic>? grupo) async {
    setState(() {
      _grupoSeleccionado = grupo;
      _selectedRecordatoriId = null;
    });
    if (grupo != null) _cargarDatosGrupo(grupo['id']);
  }

  Future<void> _cargarDatosGrupo(int grupId) async {
    try {
      final resRecs = await apiService.get('/grups/$grupId/recordatoris');
      final resNotas = await apiService.get('/grups/$grupId/notas');
      final resRanking = await apiService.get('/grups/$grupId/ranking');
      //Para el commit.

      if (mounted) {
        setState(() {
          if (_grupoSeleccionado != null) {
            _grupoSeleccionado!['membres'] = resRanking.data;
          }

          _recordatoriosGrupo.clear();
          for (var item in resRecs.data) {
            DateTime f = _soloFecha(DateTime.parse(item['dataHora']));
            _recordatoriosGrupo.putIfAbsent(f, () => []).add({
              'id': item['id'], 'mensaje': item['missatge'], 'tipo': 'tarea', 'color': Colors.blue,
              'completada': item['completat'] ?? false, 'autor': item['creadorNom'] ?? "Usuario",
              'fechaFinal': item['dataFinal'] != null ? DateTime.parse(item['dataFinal']) : null,
            });
          }
          for (var item in resNotas.data) {
            DateTime f = _soloFecha(DateTime.parse(item['data']));
            _recordatoriosGrupo.putIfAbsent(f, () => []).add({
              'id': item['id'], 'mensaje': item['titol'], 'contenido': item['contingut'],
              'tipo': 'nota', 'color': Colors.orange, 'autor': item['creadorNom'] ?? "Usuario",
            });
          }
        });
      }
    } catch (e) { debugPrint("Error datos grupo: $e"); }
  }

  Future<void> _crearGrupoEnBackend(String nombre, String codigo) async {
    try {
      print("Enviando a backend: nom=$nombre, codi=$codigo");
      final response = await apiService.post('/grups', data: {
        "nom": nombre,
        "codi": codigo // Verifica si en Java es "codi" o "codiAcces"
      });
      print("Respuesta servidor: ${response.data}");
      _cargarGruposDesdeBackend();
    } on DioException catch (e) {
      print("🔴 ERROR 500 DETALLADO:");
      print("Mensaje: ${e.message}");
      print("Respuesta del servidor: ${e.response?.data}");
    }
  }

  Future<void> _unirseAGrupoEnBackend(String codigo) async {
    try {
      await apiService.post('/grups/join', data: {"codi_acces": codigo});
      _cargarGruposDesdeBackend();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Unido con éxito!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código inválido"), backgroundColor: Colors.red));
    }
  }

  Future<void> _cargarDatosUsuarioYTienda() async {
    try {
      final responseItems = await apiService.get('/botiga');
      final responseUser = await apiService.get('/users/me');
      if (mounted) {
        setState(() {
          _itemsTienda = responseItems.data is List ? responseItems.data : [];
          _puntosUsuario = responseUser.data['punts'] ?? 0;
          _correoUsuario = responseUser.data['email'] ?? widget.correoUsuario;
          _nombreReal = responseUser.data['nom'] ?? widget.nombreUsuario;
          _apellidosReal = responseUser.data['cognoms'] ?? "";
          _rachaActual = responseUser.data['racha'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error cargando tienda/usuario: $e");
    }
  }

  Future<void> _cargarNotasDesdeBackend() async {
    try {
      final response = await apiService.get('/notas');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          for (var item in response.data) {
            DateTime fecha = _soloFecha(DateTime.parse(item['data']));
            _recordatorios.putIfAbsent(fecha, () => []).add({
              'id': item['id'], 'mensaje': item['titol'], 'contenido': item['contingut'],
              'tipo': 'nota', 'color': Colors.orange, 'completada': false,
            });
          }
        });
      }
    } catch (e) {}
  }

  Future<void> _cargarRecordatoriosDesdeBackend() async {
    try {
      final response = await apiService.get('/recordatoris');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _recordatorios.clear(); 
          for (var item in response.data) {
            DateTime fI = _soloFecha(DateTime.parse(item['dataHora']));
            DateTime? fF = item['dataFinal'] != null ? _soloFecha(DateTime.parse(item['dataFinal'])) : null;
            final d = {'id': item['id'], 'mensaje': item['missatge'], 'tipo': 'tarea', 'color': Colors.blue, 'completada': item['completat'] ?? false, 'fechaInicial': fI, 'fechaFinal': fF, 'penalizado': false};
            _recordatorios.putIfAbsent(fI, () => []).add(d);
            if (fF != null && fI != fF) _recordatorios.putIfAbsent(fF, () => []).add(d);
          }
        });
        _comprobarPenalizaciones();
      }
    } catch (e) {}
  }

  void _comprobarPenalizaciones() {
    final now = _soloFecha(DateTime.now());
    int perdidos = 0;
    _recordatorios.forEach((date, tasks) {
      for (var t in tasks) {
        if (t['tipo'] == 'tarea' && t['completada'] == false && t['fechaFinal'] != null && t['fechaFinal'].isBefore(now) && t['penalizado'] != true) {
          t['penalizado'] = true; perdidos += 15;
        }
      }
    });
    if (perdidos > 0) {
      setState(() { _puntosUsuario -= perdidos; if (_puntosUsuario < 0) _puntosUsuario = 0; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("-$perdidos pts por tareas expiradas"), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _actualizarEstadoEnBackend(Map<String, dynamic> rec, bool nuevoEstado) async {
    if (rec['id'] == null) return;
    try {
      String path = _grupoSeleccionado != null 
          ? '/grups/${_grupoSeleccionado!['id']}/recordatoris/${rec['id']}/estat'
          : '/recordatoris/${rec['id']}/estat';
      await apiService.patch(path, data: {"completat": nuevoEstado});
      setState(() => rec['completada'] = nuevoEstado);
    } catch (e) {}
  }

  Future<void> _comprarItem(int itemId) async {
    try {
      final response = await apiService.post('/botiga/comprar/$itemId');
      if (response.statusCode == 200) {
        setState(() => _puntosUsuario = response.data['nuevoSaldo'] ?? _puntosUsuario);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['mensaje'] ?? "Compra realizada"), backgroundColor: Colors.green));
        _cargarDatosUsuarioYTienda();
      }
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? "Error en la compra"), backgroundColor: Colors.red));
    }
  }

  Future<void> _equiparItem(int itemId) async {
    try {
      final response = await apiService.post('/inventari/equipar/$itemId');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Equipado correctamente!"), backgroundColor: Colors.blue));
          _cargarDatosUsuarioYTienda();
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? "Error al equipar"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _desequiparItem(int itemId) async {
    try {
      final response = await apiService.post('/inventari/desequipar/$itemId');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Desequipado correctamente!"), backgroundColor: Colors.orange));
          _cargarDatosUsuarioYTienda();
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? "Error al desequipar"), backgroundColor: Colors.red));
      }
    }
  }

  DateTime _soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  @override
  void dispose() {
    _cronometro?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<dynamic> _guardarEnBackend(String tipo, String mensaje, DateTime fecha, {String? contenido, DateTime? fechaFinal}) async {
    String fechaSimple = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    String iso = "${fechaSimple}T00:00:00";
    
    String endpoint = _grupoSeleccionado != null ? (tipo == 'nota' ? '/grups/${_grupoSeleccionado!['id']}/notas' : '/grups/${_grupoSeleccionado!['id']}/recordatoris') : (tipo == 'nota' ? '/notas' : '/recordatoris');
    
    Map<String, dynamic> datos = {};
    if (tipo == 'nota') {
      datos = {"titol": mensaje, "contingut": contenido ?? "", "data": fechaSimple};
    } else {
      datos = {"missatge": mensaje, "dataHora": iso};
      if (fechaFinal != null) {
        datos["dataFinal"] = "${fechaFinal.year}-${fechaFinal.month.toString().padLeft(2, '0')}-${fechaFinal.day.toString().padLeft(2, '0')}T23:59:59";
      }
    }

    try {
      final response = await apiService.post(endpoint, data: datos);
      return response.data;
    } catch (e) {
      debugPrint("Error guardando $tipo (500): $e");
      return null;
    }
  }

  String _nombreMes(int mes) {
    const meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    return meses[mes - 1];
  }

  Widget _calendarioPersonalizado() {
    DateTime pDM = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, 1);
    int dEM = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 0).day;
    int desfase = pDM.weekday - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_left, color: Colors.blue, size: 20), onPressed: () => setState(() => _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month - 1, 1))),
          Text("${_nombreMes(_fechaSeleccionada.month)} ${_fechaSeleccionada.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(icon: const Icon(Icons.chevron_right, color: Colors.blue, size: 20), onPressed: () => setState(() => _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 1))),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ["L", "M", "X", "J", "V", "S", "D"].map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))).toList()),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dEM + desfase,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemBuilder: (context, index) {
            if (index < desfase) return const SizedBox();
            int dia = index - desfase + 1;
            DateTime fDia = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, dia);
            bool sel = _soloFecha(_fechaSeleccionada) == _soloFecha(fDia);
            final recs = _grupoSeleccionado != null ? _recordatoriosGrupo[_soloFecha(fDia)] ?? [] : _recordatorios[_soloFecha(fDia)] ?? [];

            return GestureDetector(
              onTap: () => setState(() => _fechaSeleccionada = fDia),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: sel ? (isDark ? Colors.blue[900]?.withValues(alpha: 0.5) : Colors.blue[100]) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: sel ? Border.all(color: Colors.blue, width: 1) : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("$dia", style: TextStyle(fontSize: 16, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: recs.take(3).map((r) => Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 0.5), decoration: BoxDecoration(shape: r['tipo'] == 'tarea' ? BoxShape.rectangle : BoxShape.circle, color: r['color']))).toList())
                ]),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.note_add, color: Colors.orange), title: const Text('Nueva Nota'), onTap: () { Navigator.pop(context); _mostrarDialogoFormulario('nota'); }),
        ListTile(leading: const Icon(Icons.task_alt, color: Colors.green), title: const Text('Nuevo Recordatorio'), onTap: () { Navigator.pop(context); _mostrarDialogoFormulario('tarea'); }),
        ListTile(leading: const Icon(Icons.group_add, color: Colors.blueAccent), title: const Text('Nuevo Grupo'), onTap: () { Navigator.pop(context); _mostrarDialogoCrearGrupo(); }),
        ListTile(leading: const Icon(Icons.person_add, color: Colors.purple), title: const Text('Unirse a Grupo'), onTap: () { Navigator.pop(context); _mostrarDialogoUnirseGrupo(); }),
      ])),
    );
  }

  void _mostrarDialogoCrearGrupo() {
    String n = ""; String cod = "";
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Crear Grupo'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(decoration: const InputDecoration(labelText: 'Nombre'), onChanged: (v) => n = v), TextField(decoration: const InputDecoration(labelText: 'Código'), onChanged: (v) => cod = v)]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')), ElevatedButton(onPressed: () { if (n.isNotEmpty && cod.isNotEmpty) { _crearGrupoEnBackend(n, cod); Navigator.pop(c); } }, child: const Text('Crear'))]));
  }

  void _mostrarDialogoUnirseGrupo() {
    String cod = "";
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Unirse a Grupo'), content: TextField(decoration: const InputDecoration(labelText: 'Código del Grupo'), onChanged: (v) => cod = v), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')), ElevatedButton(onPressed: () { if (cod.isNotEmpty) { _unirseAGrupoEnBackend(cod); Navigator.pop(c); } }, child: const Text('Unirse'))]));
  }

  void _mostrarDialogoFormulario(String tipo) {
    String tit = ""; String cont = ""; String msg = ""; Color col = Colors.blue;
    DateTime fI = _fechaSeleccionada; DateTime fF = _fechaSeleccionada.add(const Duration(days: 1));
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setS) => AlertDialog(
        title: Text(tipo == 'nota' ? 'Nueva Nota' : 'Nuevo Recordatorio'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text("Inicio: ${fI.day}/${fI.month}"), leading: const Icon(Icons.calendar_today), onTap: () async { final p = await showDatePicker(context: context, initialDate: fI, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (p != null) setS(() { fI = p; if (fF.isBefore(fI)) fF = fI.add(const Duration(days: 1)); }); }),
          if (tipo == 'tarea') ListTile(title: Text("Límite: ${fF.day}/${fF.month}"), leading: const Icon(Icons.event_busy, color: Colors.redAccent), onTap: () async { final p = await showDatePicker(context: context, initialDate: fF, firstDate: fI, lastDate: DateTime(2030)); if (p != null) setS(() => fF = p); }),
          if (tipo == 'nota') ...[TextField(decoration: const InputDecoration(labelText: 'Título'), onChanged: (v) => tit = v), TextField(decoration: const InputDecoration(labelText: 'Contenido'), maxLines: 3, onChanged: (v) => cont = v)]
          else ...[TextField(decoration: const InputDecoration(labelText: 'Mensaje'), onChanged: (v) => msg = v)],
          const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple].map((c) => GestureDetector(onTap: () => setS(() => col = c), child: CircleAvatar(backgroundColor: c, radius: 15, child: col == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null))).toList()),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            if (tipo == 'nota' ? tit.isNotEmpty : msg.isNotEmpty) {
              final res = await _guardarEnBackend(tipo, tipo == 'nota' ? tit : msg, fI, contenido: cont, fechaFinal: tipo == 'tarea' ? fF : null);
              if (res != null) {
                setState(() {
                  final f = _soloFecha(fI);
                  final nuevo = {'id': (res is Map) ? res['id'] : null, 'mensaje': tipo == 'nota' ? tit : msg, 'contenido': cont, 'color': col, 'tipo': tipo, 'completada': false, 'fechaInicial': f, 'fechaFinal': fF, 'autor': widget.nombreUsuario};
                  if (_grupoSeleccionado != null) { _recordatoriosGrupo.putIfAbsent(f, () => []).add(nuevo); } 
                  else { _recordatorios.putIfAbsent(f, () => []).add(nuevo); }
                });
                if (mounted) Navigator.pop(context);
              }
            }
          }, child: const Text('Guardar')),
        ],
      )),
    );
  }

  void _confirmarDeshacerTarea(Map<String, dynamic> tarea) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(title: const Text("Deshacer tarea"), content: const Text("¿Deseas deshacer la tarea completada?"), actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
        TextButton(onPressed: () { setState(() => tarea['completada'] = false); Navigator.pop(c); }, child: const Text("Sí, deshacer")),
      ]),
    );
  }

  void _alternarCronometro() {
    if (_cronometroActivo) {
      _cronometro?.cancel();
      _animationController.stop();
      setState(() => _cronometroActivo = false);
    } else {
      if ((_tecnicaSeleccionada == 1 || _tecnicaSeleccionada == 2) && _tiempoRestante == Duration.zero) {
        _tiempoRestante = Duration(minutes: _tecnicaSeleccionada == 1 ? 25 : _estudioPersonalizado);
        _estaEnFaseEstudio = true;
      } else if (_esTemporizador && _tiempoRestante == Duration.zero) {
        _tiempoRestante = Duration(hours: _tempHoras, minutes: _tempMinutos);
      }

      if ((_esTemporizador || (_tecnicaSeleccionada != 0 && _tecnicaSeleccionada != 3)) && _tiempoRestante <= Duration.zero) return;

      setState(() => _cronometroActivo = true);
      _animationController.repeat();

      _cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_esTemporizador || (_tecnicaSeleccionada != 0 && _tecnicaSeleccionada != 3)) {
            _tiempoTranscurrido += const Duration(seconds: 1);
            _tiempoRestante -= const Duration(seconds: 1);
            if (_tiempoRestante <= Duration.zero) {
              _tiempoRestante = Duration.zero;
              if (_tecnicaSeleccionada != 0) {
                _cambiarFaseTecnica();
              } else {
                _cronometro?.cancel(); _cronometroActivo = false; _animationController.stop();
              }
            }
          } else if (_tecnicaSeleccionada == 3) {
            if (_estaEnFaseEstudio) {
              _tiempoTranscurrido += const Duration(seconds: 1);
            } else {
              _tiempoRestante -= const Duration(seconds: 1);
              if (_tiempoRestante <= Duration.zero) {
                _tiempoRestante = Duration.zero;
                _estaEnFaseEstudio = true;
                _tiempoTranscurrido = Duration.zero;
                _mostrarNotificacionFase("¡Tiempo de descanso terminado!", "Hora de volver al estudio.");
              }
            }
          } else {
            if (_estaEnFaseEstudio) {
              _tiempoTranscurrido += const Duration(seconds: 1);
            } else {
              _tiempoDescansoLibre += const Duration(seconds: 1);
            }
          }
        });
      });
    }
  }

  void _mostrarNotificacionFase(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Entendido"))],
      ),
    );
  }

  void _cambiarFaseTecnica() {
    _estaEnFaseEstudio = !_estaEnFaseEstudio;
    int mins = _tecnicaSeleccionada == 1 ? (_estaEnFaseEstudio ? 25 : 5) : (_estaEnFaseEstudio ? _estudioPersonalizado : _descansoPersonalizado);
    _tiempoRestante = Duration(minutes: mins);
    _mostrarNotificacionFase(_estaEnFaseEstudio ? "¡Hora de estudiar!" : "¡Hora de descansar!", _estaEnFaseEstudio ? "Fase de descanso terminada. ¡A por ello!" : "Buen trabajo. Tómate un respiro de $mins minutos.");
  }

  void _alternarFaseLibre() {
    setState(() {
      if (_tecnicaSeleccionada == 3) { // Flowtime
        if (_estaEnFaseEstudio) {
          int studySeconds = _tiempoTranscurrido.inSeconds;
          _tiempoRestante = Duration(seconds: (studySeconds * 0.4).round());
          _estaEnFaseEstudio = false;
        } else {
          _estaEnFaseEstudio = true;
          _tiempoTranscurrido = Duration.zero;
        }
      } else {
        _estaEnFaseEstudio = !_estaEnFaseEstudio;
      }
    });
  }


  void _resetearCronometro() {
    _cronometro?.cancel();
    _animationController.stop();
    _animationController.value = 0;
    setState(() {
      _tiempoTranscurrido = Duration.zero;
      _tiempoDescansoLibre = Duration.zero;
      _cronometroActivo = false;
      _selectedRecordatoriId = null;
      _tiempoRestante = Duration.zero;
      _estaEnFaseEstudio = true;
    });
  }
  Future<void> _guardarSesionEnBackend() async {
    int minutos = _tiempoTranscurrido.inMinutes;
    if (minutos == 0 && _tiempoTranscurrido.inSeconds > 0) minutos = 1; 

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
        int ganados = response.data['puntosGanados'] ?? 0;
        int saldo = response.data['nuevoSaldo'] ?? _puntosUsuario;

        setState(() {
          _puntosUsuario = saldo;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Éxito! Ganaste $ganados puntos. Nuevo saldo: $saldo"),
            backgroundColor: Colors.green,
          ),
        );
        
        _resetearCronometro();
        if (_grupoSeleccionado != null) {
          _cargarDatosGrupo(_grupoSeleccionado!['id']);
        } else {
          _cargarRecordatoriosDesdeBackend();
        }
        _cargarDatosUsuarioYTienda(); 
        _mostrarPopupNuevaNota(minutos, ganados);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _mostrarPopupNuevaNota(int mins, int pts) async {
    TextEditingController tC = TextEditingController();
    TextEditingController cC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¡Sesión completada! 🏆'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Has ganado $pts puntos por concentrarte $mins minutos.'),
                const SizedBox(height: 15),
                const Text('¿Qué has estudiado? Registra tu progreso:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: tC,
                  decoration: const InputDecoration(labelText: 'Título de la nota', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cC,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Resumen o apuntes (Opcional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Solo reclamar puntos'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar Nota'),
              onPressed: () {
                if (tC.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _enviarNotaAlBackend(tC.text, cC.text);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _enviarNotaAlBackend(String titol, String contingut) async {
    try {
      String fechaISO = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}T00:00:00";
      await apiService.post('/notas', data: {'titol': titol, 'contingut': contingut, 'data': fechaISO});
      _cargarNotasDesdeBackend(); 
    } catch (e) {
      debugPrint("Error al guardar la nota: $e");
    }
  }

  String _formatearTiempo(Duration d) {
    String dd(int n) => n.toString().padLeft(2, '0');
    return "${dd(d.inHours)}:${dd(d.inMinutes.remainder(60))}:${dd(d.inSeconds.remainder(60))}";
  }

  Future<void> _cerrarSesion() async {
    await TokenStorage.deleteToken();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const MenuPrincipal()), (route) => false);
  }

  Widget _paginaInicio() {
    final fA = _soloFecha(_fechaSeleccionada);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final lista = _grupoSeleccionado != null 
        ? _recordatoriosGrupo[fA] ?? []
        : _recordatorios[fA] ?? [];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('¡Bienvenido/a, ${_nombreReal.isNotEmpty ? _nombreReal : widget.nombreUsuario}!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.blue[200] : Colors.blueAccent)),
            const SizedBox(height: 10),
            Text(_grupoSeleccionado != null ? 'calendario de ${_grupoSeleccionado!['nom']}:' : 'calendario personal:', 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 570,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black12, blurRadius: 10)],
                        border: Border.all(color: isDark ? Colors.blueGrey[800]! : Colors.blue[100]!),
                      ),
                      child: _calendarioPersonalizado(),
                    ),
                    if (_grupoSeleccionado != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextButton.icon(
                          onPressed: () => _seleccionarGrupo(null),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Volver al calendario personal"),
                        ),
                      ),
                  ],
                ),
                if (_grupoSeleccionado == null && _grupos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SizedBox(
                      width: 100,
                      child: Column(
                        children: [
                          const Text("Grupos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const Divider(),
                          ..._grupos.map((g) => InkWell(
                            onTap: () => _seleccionarGrupo(g),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(g['nom'], textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, 
                                   style: const TextStyle(color: Colors.blue, fontSize: 12, decoration: TextDecoration.underline)),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 35),
            const Align(alignment: Alignment.centerLeft, child: Text("Tareas del día:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            if (lista.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text("Día libre", style: TextStyle(color: Colors.grey))),
            ...lista.map((rec) => Card(
              color: (rec['color'] as Color).withValues(alpha: 0.15),
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rec['tipo'] == 'nota' && rec['contenido'] != null) Text(rec['contenido']),
                    if (rec['autor'] != null) Text("Por: ${rec['autor']}", style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                    if (rec['tipo'] == 'tarea' && rec['fechaFinal'] != null) 
                      Text("Límite: ${rec['fechaFinal'].day}/${rec['fechaFinal'].month}", style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (rec['tipo'] == 'tarea')
                      Checkbox(
                        value: rec['completada'] ?? false,
                        onChanged: (bool? value) {
                          if (rec['completada'] == true && value == false) {
                            _confirmarDeshacerTarea(rec);
                          } else {
                            _actualizarEstadoEnBackend(rec, value ?? false);
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
            )),
          ],
        ),
      ),
    );
  }

  Widget _paginaExplorar() {
    final recordatoriosActuales = _grupoSeleccionado != null ? _recordatoriosGrupo : _recordatorios;
    
    final todasLasTareas = recordatoriosActuales.values
        .expand((lista) => lista)
        .where((r) => r['tipo'] == 'tarea' && (r['completada'] == false))
        .toSet() 
        .toList();

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Técnicas de estudio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text("Ninguna"), selected: _tecnicaSeleccionada == 0, onSelected: (v) { if (!_cronometroActivo) setState(() => _tecnicaSeleccionada = 0); }),
                ChoiceChip(label: const Text("Pomodoro"), selected: _tecnicaSeleccionada == 1, onSelected: (v) { if (!_cronometroActivo) setState(() => _tecnicaSeleccionada = 1); }),
                ChoiceChip(label: const Text("Personalizada"), selected: _tecnicaSeleccionada == 2, onSelected: (v) { if (!_cronometroActivo) setState(() => _tecnicaSeleccionada = 2); }),
                ChoiceChip(label: const Text("Flowtime"), selected: _tecnicaSeleccionada == 3, onSelected: (v) { if (!_cronometroActivo) setState(() { _tecnicaSeleccionada = 3; _esTemporizador = false; }); }),
              ],
            ),
            const SizedBox(height: 20),

            if (_tecnicaSeleccionada == 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(label: const Text("Cronómetro"), selected: !_esTemporizador, onSelected: (v) { if (!_cronometroActivo) setState(() => _esTemporizador = false); }),
                  const SizedBox(width: 10),
                  ChoiceChip(label: const Text("Temporizador"), selected: _esTemporizador, onSelected: (v) { if (!_cronometroActivo) setState(() => _esTemporizador = true); }),
                ],
              ),
            const SizedBox(height: 20),

            if (!_cronometroActivo) ...[
              const Text("Trabajar en:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: _selectedRecordatoriId,
                hint: const Text("Selecciona una tarea"),
                onChanged: (int? newValue) => setState(() => _selectedRecordatoriId = newValue),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text("Sin tarea asignada")),
                  ...todasLasTareas.map((tarea) => DropdownMenuItem<int>(
                    value: tarea['id'],
                    child: Text(tarea['mensaje']),
                  )),
                ],
              ),
            ] else if (_selectedRecordatoriId != null) ...[
              Text(
                "Tarea actual: ${todasLasTareas.firstWhere((t) => t['id'] == _selectedRecordatoriId, orElse: () => {'mensaje': '...' })['mensaje']}",
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
              ),
            ],
            
            const SizedBox(height: 20),

            if (_tecnicaSeleccionada == 2 && !_cronometroActivo && _tiempoTranscurrido == Duration.zero)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text("Estudio (m)"),
                      DropdownButton<int>(
                        value: _estudioPersonalizado,
                        items: [15, 20, 25, 30, 45, 50, 60].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
                        onChanged: (v) => setState(() => _estudioPersonalizado = v!),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      const Text("Descanso (m)"),
                      DropdownButton<int>(
                        value: _descansoPersonalizado,
                        items: [5, 10, 15, 20].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
                        onChanged: (v) => setState(() => _descansoPersonalizado = v!),
                      ),
                    ],
                  ),
                ],
              )
            else if (_tecnicaSeleccionada == 0 && _esTemporizador && !_cronometroActivo && _tiempoTranscurrido == Duration.zero)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text("Horas"),
                      DropdownButton<int>(
                        value: _tempHoras,
                        items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("$i h"))),
                        onChanged: (v) => setState(() => _tempHoras = v!),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      const Text("Minutos"),
                      DropdownButton<int>(
                        value: _tempMinutos,
                        items: List.generate(60, (i) => DropdownMenuItem(value: i, child: Text("$i m"))),
                        onChanged: (v) => setState(() => _tempMinutos = v!),
                      ),
                    ],
                  ),
                ],
              ),

            // 1. EL TEXTO DE FASE (Ahora se muestra también en cronómetro libre si ha empezado)
            if (_tecnicaSeleccionada != 0 || (_tecnicaSeleccionada == 0 && !_esTemporizador && (_cronometroActivo || _tiempoTranscurrido > Duration.zero || _tiempoDescansoLibre > Duration.zero)))
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_estaEnFaseEstudio ? "FASE: ESTUDIO" : "FASE: DESCANSO",
                      style: TextStyle(fontWeight: FontWeight.bold, color: _estaEnFaseEstudio ? Colors.red : Colors.green)
                  )
              ),

            // 2. EL TEXTO GIGANTE DEL RELOJ
            Text(
                (_esTemporizador || (_tecnicaSeleccionada != 0 && _tecnicaSeleccionada != 3))
                    ? (_cronometroActivo || _tiempoTranscurrido > Duration.zero ? _formatearTiempo(_tiempoRestante) : _formatearTiempo(Duration(hours: _tempHoras, minutes: _tecnicaSeleccionada == 1 ? 25 : (_tecnicaSeleccionada == 2 ? _estudioPersonalizado : _tempMinutos))))
                    : (_tecnicaSeleccionada == 3)
                      ? (_estaEnFaseEstudio ? _formatearTiempo(_tiempoTranscurrido) : _formatearTiempo(_tiempoRestante))
                      : (_estaEnFaseEstudio ? _formatearTiempo(_tiempoTranscurrido) : _formatearTiempo(_tiempoDescansoLibre)),
                style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold, fontFamily: 'monospace')
            ),

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


                if ((_tecnicaSeleccionada == 0 || _tecnicaSeleccionada == 3) && !_esTemporizador && _cronometroActivo)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ElevatedButton.icon(
                      onPressed: _alternarFaseLibre,
                      icon: Icon(_estaEnFaseEstudio ? Icons.coffee : Icons.menu_book),
                      label: Text(_estaEnFaseEstudio ? 'Descansar' : 'Estudiar'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _estaEnFaseEstudio ? Colors.purple : Colors.blueAccent,
                          foregroundColor: Colors.white
                      ),
                    ),
                  ),

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
      ),
    );
  }

  Widget _paginaTiendaORanking() {
    if (_grupoSeleccionado != null) {
      return GroupRanking(members: _grupoSeleccionado!['membres'] ?? []);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue[800]!]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10)],
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
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _itemsTienda.length,
                itemBuilder: (context, index) {
                  final item = _itemsTienda[index];
                  final bool comprat = item['comprat'] ?? false;
                  final bool equipat = item['equipat'] ?? false;
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.redeem, size: 40, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(item['nom'] ?? 'Item', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("${item['preu']} pts", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 11)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: comprat 
                            ? (equipat ? () => _desequiparItem(item['id']) : () => _equiparItem(item['id']))
                            : () => _comprarItem(item['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: equipat ? Colors.orange : (comprat ? Colors.green : Colors.blueAccent),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            comprat ? (equipat ? "Quitar" : "Equipar") : "Comprar",
                            style: const TextStyle(fontSize: 11),
                          ),
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
      body: [_paginaInicio(), _paginaExplorar(), _paginaTiendaORanking(), _paginaPerfil()][_indiceActual],
      floatingActionButton: FloatingActionButton(onPressed: _mostrarOpcionesFab, backgroundColor: Colors.blue, foregroundColor: Colors.white, child: const Icon(Icons.add)),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue, selectedItemColor: Colors.white, unselectedItemColor: Colors.blue[100], type: BottomNavigationBarType.fixed,
        currentIndex: _indiceActual, onTap: (index) => setState(() => _indiceActual = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          const BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reloj'),
          BottomNavigationBarItem(
            icon: Icon(_grupoSeleccionado != null ? Icons.leaderboard : Icons.shopping_cart), 
            label: _grupoSeleccionado != null ? 'Ranking' : 'Tienda'
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
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
