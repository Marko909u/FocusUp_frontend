import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'settings.dart';
import 'api_service.dart';
import 'token_storage.dart';
import 'group_widgets.dart';

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
  int _tecnicaSeleccionada = 0; // 0: Ninguna, 1: Pomodoro, 2: Personalizada
  bool _estaEnFaseEstudio = true;
  int _tempHoras = 0;
  int _tempMinutos = 25;
  int _estudioPersonalizado = 25;
  int _descansoPersonalizado = 5;
  Duration _tiempoRestante = Duration.zero;

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
      final response = await apiService.get('/grups');
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
      if (mounted) {
        setState(() {
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
      await apiService.post('/grups', data: {"nom": nombre, "codi": codigo});
      _cargarGruposDesdeBackend();
    } catch (e) { debugPrint("Error creando grupo: $e"); }
  }

  Future<void> _unirseAGrupoEnBackend(String codigo) async {
    try {
      await apiService.post('/grups/unir', data: {"codi": codigo});
      _cargarGruposDesdeBackend();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código inválido")));
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
    } catch (e) { debugPrint("Error usuario/tienda: $e"); }
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
      String path = _grupoSeleccionado != null ? '/grups/${_grupoSeleccionado!['id']}/recordatoris/${rec['id']}/estat' : '/recordatoris/${rec['id']}/estat';
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? "Error al equipar"), backgroundColor: Colors.red));
    }
  }

  DateTime _soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  @override
  void dispose() { _cronometro?.cancel(); _animationController.dispose(); super.dispose(); }

  Future<dynamic> _guardarEnBackend(String tipo, String mensaje, DateTime fecha, {String? contenido, DateTime? fechaFinal}) async {
    String fechaCorta = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    String iso = "${fechaCorta}T00:00:00";
    String endpoint = _grupoSeleccionado != null ? (tipo == 'nota' ? '/grups/${_grupoSeleccionado!['id']}/notas' : '/grups/${_grupoSeleccionado!['id']}/recordatoris') : (tipo == 'nota' ? '/notas' : '/recordatoris');
    Map<String, dynamic> data = tipo == 'nota' ? {"titol": mensaje, "contingut": contenido ?? "", "data": fechaCorta} : {"missatge": mensaje, "dataHora": iso};
    if (fechaFinal != null) data["dataFinal"] = "${fechaFinal.year}-${fechaFinal.month.toString().padLeft(2, '0')}-${fechaFinal.day.toString().padLeft(2, '0')}T23:59:59";
    try { final r = await apiService.post(endpoint, data: data); return r.data; } catch (e) { debugPrint("Error backend: $e"); return null; }
  }

  String _nombreMes(int mes) {
    const meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    return meses[mes - 1];
  }

  Widget _calendarioPersonalizado() {
    DateTime pD = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, 1);
    int dM = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 0).day;
    int df = pD.weekday - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.chevron_left, color: Colors.blue, size: 20), onPressed: () => setState(() => _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month - 1, 1))),
        Text("${_nombreMes(_fechaSeleccionada.month)} ${_fechaSeleccionada.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        IconButton(icon: const Icon(Icons.chevron_right, color: Colors.blue, size: 20), onPressed: () => setState(() => _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 1))),
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ["L","M","X","J","V","S","D"].map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10))).toList()),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: dM + df, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7), itemBuilder: (c, i) {
        if (i < df) return const SizedBox();
        int d = i - df + 1; DateTime fDia = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, d);
        bool sel = _soloFecha(_fechaSeleccionada) == _soloFecha(fDia);
        final recs = _grupoSeleccionado != null ? _recordatoriosGrupo[_soloFecha(fDia)] ?? [] : _recordatorios[_soloFecha(fDia)] ?? [];
        return GestureDetector(onTap: () => setState(() => _fechaSeleccionada = fDia), child: Container(margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: sel ? (isDark ? Colors.blue[900]?.withValues(alpha: 0.5) : Colors.blue[100]) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: sel ? Border.all(color: Colors.blue, width: 1) : null), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("$d", style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: recs.take(3).map((r) => Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 0.5), decoration: BoxDecoration(shape: r['tipo'] == 'tarea' ? BoxShape.rectangle : BoxShape.circle, color: r['color']))).toList())
        ])));
      })
    ]);
  }

  void _mostrarOpcionesFab() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c) => Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.note_add, color: Colors.orange), title: const Text('Nueva Nota'), onTap: () { Navigator.pop(c); _mostrarDialogoFormulario('nota'); }),
      ListTile(leading: const Icon(Icons.task_alt, color: Colors.green), title: const Text('Nuevo Recordatorio'), onTap: () { Navigator.pop(c); _mostrarDialogoFormulario('tarea'); }),
      ListTile(leading: const Icon(Icons.group_add, color: Colors.blue), title: const Text('Nuevo Grupo'), onTap: () { Navigator.pop(c); _mostrarDialogoCrearGrupo(); }),
      ListTile(leading: const Icon(Icons.person_add, color: Colors.purple), title: const Text('Unirse a Grupo'), onTap: () { Navigator.pop(c); _mostrarDialogoUnirseGrupo(); }),
    ])));
  }

  void _mostrarDialogoCrearGrupo() {
    String n = ""; String cod = "";
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Crear Grupo'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(decoration: const InputDecoration(labelText: 'Nombre'), onChanged: (v) => n = v), TextField(decoration: const InputDecoration(labelText: 'Código'), onChanged: (v) => cod = v)]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')), ElevatedButton(onPressed: () { if (n.isNotEmpty && cod.isNotEmpty) { _crearGrupoEnBackend(n, cod); Navigator.pop(c); } }, child: const Text('Crear'))]));
  }

  void _mostrarDialogoUnirseGrupo() {
    String cod = "";
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Unirse a Grupo'), content: TextField(decoration: const InputDecoration(labelText: 'Código'), onChanged: (v) => cod = v), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')), ElevatedButton(onPressed: () { if (cod.isNotEmpty) { _unirseAGrupoEnBackend(cod); Navigator.pop(c); } }, child: const Text('Unirse'))]));
  }

  void _mostrarDialogoFormulario(String tipo) {
    String tit = ""; String cont = ""; String msg = ""; Color col = Colors.blue;
    DateTime fI = _fechaSeleccionada; DateTime fF = _fechaSeleccionada.add(const Duration(days: 1));
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(title: Text(tipo == 'nota' ? 'Nueva Nota' : 'Nuevo Recordatorio'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(title: Text("Inicio: ${fI.day}/${fI.month}"), leading: const Icon(Icons.calendar_today), onTap: () async { final p = await showDatePicker(context: c, initialDate: fI, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (p != null) setS(() { fI = p; if (fF.isBefore(fI)) fF = fI.add(const Duration(days: 1)); }); }),
      if (tipo == 'tarea') ListTile(title: Text("Límite: ${fF.day}/${fF.month}"), leading: const Icon(Icons.event_busy, color: Colors.redAccent), onTap: () async { final p = await showDatePicker(context: c, initialDate: fF, firstDate: fI, lastDate: DateTime(2030)); if (p != null) setS(() => fF = p); }),
      if (tipo == 'nota') ...[TextField(decoration: const InputDecoration(labelText: 'Título'), onChanged: (v) => tit = v), TextField(decoration: const InputDecoration(labelText: 'Contenido'), maxLines: 3, onChanged: (v) => cont = v)]
      else ...[TextField(decoration: const InputDecoration(labelText: 'Mensaje'), onChanged: (v) => msg = v)],
      const SizedBox(height: 15), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple].map((c) => GestureDetector(onTap: () => setS(() => col = c), child: CircleAvatar(backgroundColor: c, radius: 15, child: col == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null))).toList())
    ])), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')), ElevatedButton(onPressed: () async { if (tipo == 'nota' ? tit.isNotEmpty : msg.isNotEmpty) { final res = await _guardarEnBackend(tipo, tipo == 'nota' ? tit : msg, fI, contenido: cont, fechaFinal: tipo == 'tarea' ? fF : null); if (res != null) { setState(() { final f = _soloFecha(fI); final nuevo = {'id': (res is Map) ? res['id'] : null, 'mensaje': tipo == 'nota' ? tit : msg, 'contenido': cont, 'color': col, 'tipo': tipo, 'completada': false, 'fechaInicial': f, 'fechaFinal': fF, 'autor': widget.nombreUsuario}; if (_grupoSeleccionado != null) { _recordatoriosGrupo.putIfAbsent(f, () => []).add(nuevo); } else { _recordatorios.putIfAbsent(f, () => []).add(nuevo); } }); if (c.mounted) Navigator.pop(c); } } }, child: const Text('Guardar'))])));
  }

  void _confirmarDeshacerTarea(Map<String, dynamic> tarea) {
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Deshacer tarea"), content: const Text("¿Deseas deshacer la tarea completada?"), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")), TextButton(onPressed: () { setState(() => tarea['completada'] = false); Navigator.pop(c); }, child: const Text("Sí, deshacer"))]));
  }

  void _alternarCronometro() {
    if (_cronometroActivo) { _cronometro?.cancel(); _animationController.stop(); setState(() => _cronometroActivo = false); }
    else {
      if (_tecnicaSeleccionada != 0 && _tiempoRestante == Duration.zero) { _tiempoRestante = Duration(minutes: _tecnicaSeleccionada == 1 ? 25 : _estudioPersonalizado); _estaEnFaseEstudio = true; }
      else if (_esTemporizador && _tiempoRestante == Duration.zero) { _tiempoRestante = Duration(hours: _tempHoras, minutes: _tempMinutos); }
      if ((_esTemporizador || _tecnicaSeleccionada != 0) && _tiempoRestante <= Duration.zero) return;
      setState(() => _cronometroActivo = true); _animationController.repeat();
      _cronometro = Timer.periodic(const Duration(seconds: 1), (t) { setState(() { _tiempoTranscurrido += const Duration(seconds: 1); if (_esTemporizador || _tecnicaSeleccionada != 0) { _tiempoRestante -= const Duration(seconds: 1); if (_tiempoRestante <= Duration.zero) { _tiempoRestante = Duration.zero; if (_tecnicaSeleccionada != 0) _cambiarFaseTecnica(); else { _cronometro?.cancel(); _cronometroActivo = false; _animationController.stop(); } } } }); });
    }
  }

  void _cambiarFaseTecnica() {
    _estaEnFaseEstudio = !_estaEnFaseEstudio;
    int mins = _tecnicaSeleccionada == 1 ? (_estaEnFaseEstudio ? 25 : 5) : (_estaEnFaseEstudio ? _estudioPersonalizado : _descansoPersonalizado);
    _tiempoRestante = Duration(minutes: mins);
    showDialog(context: context, builder: (c) => AlertDialog(title: Text(_estaEnFaseEstudio ? "¡Hora de estudiar!" : "¡Hora de descansar!"), content: Text(_estaEnFaseEstudio ? "Fase de descanso terminada. ¡A por ello!" : "Buen trabajo. Tómate un respiro de $mins minutos."), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Entendido"))]));
  }

  void _resetearCronometro() { _cronometro?.cancel(); _animationController.stop(); _animationController.value = 0; setState(() { _tiempoTranscurrido = Duration.zero; _cronometroActivo = false; _selectedRecordatoriId = null; _tiempoRestante = Duration.zero; _estaEnFaseEstudio = true; }); }

  Future<void> _guardarSesionEnBackend() async {
    int minutos = _tiempoTranscurrido.inMinutes; if (minutos == 0 && _tiempoTranscurrido.inSeconds > 0) minutos = 1; if (minutos <= 0) return;
    try {
      final res = await apiService.post('/sessions', data: {"minuts": minutos, if (_selectedRecordatoriId != null) "recordatoriId": _selectedRecordatoriId});
      if (res.statusCode == 200) {
        setState(() => _puntosUsuario = res.data['nuevoSaldo'] ?? _puntosUsuario);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Éxito! Ganaste ${res.data['puntosGanados']} puntos."), backgroundColor: Colors.green));
        _resetearCronometro();
        if (_grupoSeleccionado != null) _cargarDatosGrupo(_grupoSeleccionado!['id']); else _cargarRecordatoriosDesdeBackend();
        _cargarDatosUsuarioYTienda();
      }
    } catch (e) {}
  }

  String _formatearTiempo(Duration d) { String dd(int n) => n.toString().padLeft(2, '0'); return "${dd(d.inHours)}:${dd(d.inMinutes.remainder(60))}:${dd(d.inSeconds.remainder(60))}"; }

  Future<void> _cerrarSesion() async { await TokenStorage.deleteToken(); if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const MenuPrincipal()), (r) => false); }

  Widget _paginaInicio() {
    final fA = _soloFecha(_fechaSeleccionada); final isDark = Theme.of(context).brightness == Brightness.dark;
    final lista = _grupoSeleccionado != null ? _recordatoriosGrupo[fA] ?? [] : _recordatorios[fA] ?? [];
    return SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(children: [
      Text('¡Hola, ${_nombreReal.isNotEmpty ? _nombreReal : widget.nombreUsuario}!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.blue[200] : Colors.blueAccent)),
      const SizedBox(height: 5), Text(_grupoSeleccionado != null ? 'calendario de ${_grupoSeleccionado!['nom']}:' : 'calendario personal:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 280, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black12, blurRadius: 10)], border: Border.all(color: isDark ? Colors.blueGrey[800]! : Colors.blue[100]!)), child: _calendarioPersonalizado()),
          if (_grupoSeleccionado != null) Padding(padding: const EdgeInsets.only(top: 10), child: TextButton.icon(onPressed: () => _seleccionarGrupo(null), icon: const Icon(Icons.arrow_back), label: const Text("Volver al personal", style: TextStyle(fontSize: 12))))
        ]),
        if (_grupoSeleccionado == null && _grupos.isNotEmpty) ...[const SizedBox(width: 15), Container(width: 80, child: Column(children: [const Text("Grupos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)), const Divider(), ..._grupos.map((g) => InkWell(onTap: () => _seleccionarGrupo(g), child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(g['nom'], textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blue, fontSize: 10, decoration: TextDecoration.underline))))).toList()]))]
      ]),
      const SizedBox(height: 25), const Align(alignment: Alignment.centerLeft, child: Text("Tareas del día:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
      if (lista.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text("Día libre", style: TextStyle(color: Colors.grey))),
      ...lista.map((rec) => Card(color: (rec['color'] as Color).withValues(alpha: 0.1), elevation: 0, margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(leading: CircleAvatar(backgroundColor: rec['color'], radius: 6, child: rec['tipo'] == 'tarea' ? Container(width: 6, height: 6, color: rec['color']) : null), title: Text(rec['mensaje'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, decoration: (rec['completada'] ?? false) ? TextDecoration.lineThrough : null, color: (rec['completada'] ?? false) ? Colors.grey : null)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (rec['tipo'] == 'nota' && rec['contenido'] != null) Text(rec['contenido'], style: const TextStyle(fontSize: 12)), if (rec['autor'] != null) Text("Por: ${rec['autor']}", style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)), if (rec['tipo'] == 'tarea' && rec['fechaFinal'] != null) Text("Límite: ${rec['fechaFinal'].day}/${rec['fechaFinal'].month}", style: const TextStyle(fontSize: 10, color: Colors.red))]), trailing: rec['tipo'] == 'tarea' ? Checkbox(value: rec['completada'] ?? false, onChanged: (rec['completada'] == true) ? (v) => _confirmarDeshacerTarea(rec) : (v) => _actualizarEstadoEnBackend(rec, true)) : null))).toList(),
    ])));
  }

  Widget _paginaExplorar() {
    final recordatoriosActuales = _grupoSeleccionado != null ? _recordatoriosGrupo : _recordatorios;
    final recs = recordatoriosActuales.values.expand((l) => l).where((r) => r['tipo'] == 'tarea' && r['completada'] == false).toSet().toList();
    return Center(child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("Técnicas de estudio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 10),
      Wrap(spacing: 8, children: [ChoiceChip(label: const Text("Ninguna"), selected: _tecnicaSeleccionada == 0, onSelected: (v) { if (!_cronometroActivo) setState(() => _tecnicaSeleccionada = 0); }), ChoiceChip(label: const Text("Pomodoro"), selected: _tecnicaSeleccionada == 1, onSelected: (v) { if (!_cronometroActivo) setState(() => _tecnicaSeleccionada = 1); }), ChoiceChip(label: const Text("Personalizada"), selected: _tecnicaSeleccionada == 2, onSelected: (v) { if (!_cronometroActivo) setState(() => _tecnicaSeleccionada = 2); })]),
      const SizedBox(height: 20), if (_tecnicaSeleccionada == 0) Row(mainAxisAlignment: MainAxisAlignment.center, children: [ChoiceChip(label: const Text("Cronómetro"), selected: !_esTemporizador, onSelected: (v) { if (!_cronometroActivo) setState(() => _esTemporizador = false); }), const SizedBox(width: 10), ChoiceChip(label: const Text("Temporizador"), selected: _esTemporizador, onSelected: (v) { if (!_cronometroActivo) setState(() => _esTemporizador = true); })]),
      const SizedBox(height: 20), if (!_cronometroActivo) DropdownButton<int>(value: _selectedRecordatoriId, hint: const Text("Seleccionar tarea"), onChanged: (v) => setState(() => _selectedRecordatoriId = v), items: [const DropdownMenuItem<int>(value: null, child: Text("Sin tarea")), ...recs.map((t) => DropdownMenuItem<int>(value: t['id'], child: Text(t['mensaje'])))]) else if (_selectedRecordatoriId != null) Text("Tarea: ${recs.firstWhere((t) => t['id'] == _selectedRecordatoriId, orElse: () => {'mensaje': ''})['mensaje']}", style: const TextStyle(color: Colors.blue, fontStyle: FontStyle.italic)),
      const SizedBox(height: 20), if (_tecnicaSeleccionada == 2 && !_cronometroActivo && _tiempoTranscurrido == Duration.zero) Row(mainAxisAlignment: MainAxisAlignment.center, children: [Column(children: [const Text("Estudio (m)"), DropdownButton<int>(value: _estudioPersonalizado, items: [15, 20, 25, 30, 45, 50, 60].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(), onChanged: (v) => setState(() => _estudioPersonalizado = v!))]), const SizedBox(width: 20), Column(children: [const Text("Descanso (m)"), DropdownButton<int>(value: _descansoPersonalizado, items: [5, 10, 15, 20].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(), onChanged: (v) => setState(() => _descansoPersonalizado = v!))])])
      else if (_tecnicaSeleccionada == 0 && _esTemporizador && !_cronometroActivo && _tiempoTranscurrido == Duration.zero) Row(mainAxisAlignment: MainAxisAlignment.center, children: [DropdownButton<int>(value: _tempHoras, items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("$i h"))), onChanged: (v) => setState(() => _tempHoras = v!)), const SizedBox(width: 15), DropdownButton<int>(value: _tempMinutos, items: List.generate(60, (i) => DropdownMenuItem(value: i, child: Text("$i m"))), onChanged: (v) => setState(() => _tempMinutos = v!))]),
      if (_tecnicaSeleccionada != 0) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_estaEnFaseEstudio ? "FASE: ESTUDIO" : "FASE: DESCANSO", style: TextStyle(fontWeight: FontWeight.bold, color: _estaEnFaseEstudio ? Colors.red : Colors.green))),
      Text(_esTemporizador || _tecnicaSeleccionada != 0 ? (_cronometroActivo || _tiempoTranscurrido > Duration.zero ? _formatearTiempo(_tiempoRestante) : _formatearTiempo(Duration(hours: _tempHoras, minutes: _tecnicaSeleccionada == 1 ? 25 : (_tecnicaSeleccionada == 2 ? _estudioPersonalizado : _tempMinutos)))) : _formatearTiempo(_tiempoTranscurrido), style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      Container(height: 40, width: 200, child: AnimatedBuilder(animation: _animationController, builder: (c, ch) => CustomPaint(painter: WavePainter(_animationController.value, _cronometroActivo)))),
      const SizedBox(height: 40), Row(mainAxisAlignment: MainAxisAlignment.center, children: [ElevatedButton.icon(onPressed: _alternarCronometro, icon: Icon(_cronometroActivo ? Icons.pause : Icons.play_arrow), label: Text(_cronometroActivo ? 'Parar' : 'Iniciar'), style: ElevatedButton.styleFrom(backgroundColor: _cronometroActivo ? Colors.orange : Colors.green, foregroundColor: Colors.white)), const SizedBox(width: 10), ElevatedButton.icon(onPressed: _guardarSesionEnBackend, icon: const Icon(Icons.save), label: const Text('Finalizar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white)), const SizedBox(width: 10), ElevatedButton.icon(onPressed: _resetearCronometro, icon: const Icon(Icons.refresh), label: const Text('Reset'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white))])
    ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FocusUp'), automaticallyImplyLeading: false, actions: [Row(children: [const Icon(Icons.stars, color: Colors.amber, size: 20), const SizedBox(width: 4), Text('$_puntosUsuario', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 12), const Icon(Icons.whatshot, color: Colors.orange), const SizedBox(width: 4), Text('$_rachaActual', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 16)])]),
      body: [_paginaInicio(), _paginaExplorar(), _grupoSeleccionado != null ? GroupRanking(members: _grupoSeleccionado!['membres'] ?? []) : _paginaTiendaOriginal(), _paginaPerfil()][_indiceActual],
      floatingActionButton: FloatingActionButton(onPressed: _mostrarOpcionesFab, child: const Icon(Icons.add), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      bottomNavigationBar: BottomNavigationBar(backgroundColor: Colors.blue, selectedItemColor: Colors.white, unselectedItemColor: Colors.blue[100], type: BottomNavigationBarType.fixed, currentIndex: _indiceActual, onTap: (index) => setState(() => _indiceActual = index), items: [const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'), const BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reloj'), BottomNavigationBarItem(icon: Icon(_grupoSeleccionado != null ? Icons.leaderboard : Icons.shopping_cart), label: _grupoSeleccionado != null ? 'Ranking' : 'Tienda'), const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil')]),
    );
  }

  Widget _paginaTiendaOriginal() {
    return Column(children: [Padding(padding: const EdgeInsets.all(16.0), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue[800]!]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Puntos:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Row(children: [const Icon(Icons.stars, color: Colors.amber, size: 28), const SizedBox(width: 8), Text("$_puntosUsuario", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))])]))), Expanded(child: _itemsTienda.isEmpty ? const Center(child: CircularProgressIndicator()) : GridView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _itemsTienda.length, itemBuilder: (context, index) {
      final item = _itemsTienda[index];
      final bool comprat = item['comprat'] ?? false;
      final bool equipat = item['equipat'] ?? false;
      return Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.redeem, size: 50, color: Colors.blue), const SizedBox(height: 10), Text(item['nom'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text("${item['preu']} pts", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)), const SizedBox(height: 12),
        ElevatedButton(
          onPressed: equipat ? null : (comprat ? () => _equiparItem(item['id']) : () => _comprarItem(item['id'])),
          style: ElevatedButton.styleFrom(backgroundColor: equipat ? Colors.grey : (comprat ? Colors.green : Colors.blueAccent), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(equipat ? "Equipado" : (comprat ? "Equipar" : "Comprar")),
        )
      ]));
    }))]);
  }

  Widget _paginaPerfil() {
    return SingleChildScrollView(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0), child: Column(children: [const CircleAvatar(radius: 60, backgroundColor: Colors.blue, child: Icon(Icons.person, size: 80, color: Colors.white)), const SizedBox(height: 20), Text("$_nombreReal $_apellidosReal".trim().isNotEmpty ? "$_nombreReal $_apellidosReal" : widget.nombreUsuario, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), Text(_correoUsuario, style: const TextStyle(fontSize: 16, color: Colors.grey)), const SizedBox(height: 40), Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Column(children: [ListTile(leading: const Icon(Icons.settings, color: Colors.blue), title: const Text('Configuración'), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()))), const Divider(height: 1), ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Cerrar Sesión'), onTap: _cerrarSesion)]))])));
  }
}

class WavePainter extends CustomPainter {
  final double progress; final bool activo; WavePainter(this.progress, this.activo);
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = Colors.green..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round; final path = Path(); final width = size.width; final midHeight = size.height / 2; path.moveTo(0, midHeight); if (activo) { for (double i = 0; i <= width; i++) { final y = midHeight + math.sin((i / width * 2 * math.pi * 3) + (progress * 2 * math.pi)) * 10; path.lineTo(i, y); } } else { path.lineTo(width, midHeight); } canvas.drawPath(path, paint); }
  @override bool shouldRepaint(covariant WavePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.activo != activo;
}
