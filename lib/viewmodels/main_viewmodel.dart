import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:focusup/core/api_service.dart';



class MainViewModel extends ChangeNotifier {
  int indiceActual = 0;
  String correoUsuario = "";
  String nombreReal = "";
  String apellidosReal = "";
  DateTime fechaSeleccionada = DateTime.now();
  int puntosUsuario = 0;
  int rachaActual = 0;
  int? selectedRecordatoriId;
  List<dynamic> itemsTienda = [];
  List<dynamic> grupos = [];

  Map<String, dynamic>? grupoSeleccionado;
  final Map<DateTime, List<Map<String, dynamic>>> recordatoriosGrupo = {};
  final Map<DateTime, List<Map<String, dynamic>>> recordatorios = {};


  bool esTemporizador = false;
  int tecnicaSeleccionada = 0; // 0: Ninguna, 1: Pomodoro, 2: Personalizada, 3: Flowtime
  bool estaEnFaseEstudio = true;
  int tempHoras = 0;
  int tempMinutos = 25;
  int estudioPersonalizado = 25;
  int descansoPersonalizado = 5;
  Duration tiempoRestante = Duration.zero;
  Duration tiempoDescansoLibre = Duration.zero;
  int minutosTotalesEstudiados = 0;
  int tareasCompletadas = 0;

  // Controladores de sistema
  Timer? _cronometro;
  Duration tiempoTranscurrido = Duration.zero;
  bool cronometroActivo = false;

  final AudioPlayer reproductorMusica = AudioPlayer();
  late AnimationController animationController;

  // Variable de configuración de sonido local
  bool sonidoHabilitado = true;


  void setIndice(int index) {
    indiceActual = index;
    notifyListeners();
  }

  void cambiarFechaSeleccionada(DateTime nuevaFecha) {
    fechaSeleccionada = nuevaFecha;
    notifyListeners();
  }

  void setRecordatoriId(int? id) {
    selectedRecordatoriId = id;
    notifyListeners();
  }

  void setTecnicaSeleccionada(int tecnica) {
    tecnicaSeleccionada = tecnica;
    if (tecnica == 3) esTemporizador = false;
    notifyListeners();
  }

  void setEsTemporizador(bool valor) {
    esTemporizador = valor;
    notifyListeners();
  }

  void setEstudioPersonalizado(int mins) {
    estudioPersonalizado = mins;
    notifyListeners();
  }

  void setDescansoPersonalizado(int mins) {
    descansoPersonalizado = mins;
    notifyListeners();
  }

  void setTempHoras(int horas) {
    tempHoras = horas;
    notifyListeners();
  }

  void setTempMinutos(int minutos) {
    tempMinutos = minutos;
    notifyListeners();
  }

  DateTime soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  String nombreMes(int mes) {
    const meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    return meses[mes - 1];
  }

  String formatearTiempo(Duration d) {
    String dd(int n) => n.toString().padLeft(2, '0');
    return "${dd(d.inHours)}:${dd(d.inMinutes.remainder(60))}:${dd(d.inSeconds.remainder(60))}";
  }

  bool musicaEstaEquipada() {
    return itemsTienda.any((item) =>
    item['equipat'] == true &&
        (item['tipus'] == 'MUSICA' || item['nom'] == 'Pista de Estudio Lo-Fi')
    );
  }

  Future<void> aplicarVolumen(bool habilitado) async {
    sonidoHabilitado = habilitado;
    await reproductorMusica.setVolume(sonidoHabilitado ? 1.0 : 0.0);
    notifyListeners();
  }

  //Llamada al backend

  Future<void> cargarGruposDesdeBackend() async {
    try {
      final response = await apiService.get('/grups/me');
      grupos = response.data;
      notifyListeners();
    } catch (e) { debugPrint("Error grupos: $e"); }
  }

  Future<void> seleccionarGrupo(Map<String, dynamic>? grupo) async {
    grupoSeleccionado = grupo;
    selectedRecordatoriId = null;
    notifyListeners();
    if (grupo != null) await cargarDatosGrupo(grupo['id']);
  }

  Future<void> cargarDatosGrupo(int grupId) async {
    try {
      final resRecs = await apiService.get('/grups/$grupId/recordatoris');
      final resNotas = await apiService.get('/grups/$grupId/notas');
      final resRanking = await apiService.get('/grups/$grupId/ranking');

      if (grupoSeleccionado != null) {
        grupoSeleccionado!['membres'] = resRanking.data;
      }

      recordatoriosGrupo.clear();
      for (var item in resRecs.data) {
        DateTime f = soloFecha(DateTime.parse(item['dataHora']));
        recordatoriosGrupo.putIfAbsent(f, () => []).add({
          'id': item['id'], 'mensaje': item['missatge'], 'tipo': 'tarea', 'color': Colors.blue,
          'completada': item['completat'] ?? false, 'autor': item['creadorNom'] ?? "Usuario",
          'fechaFinal': item['dataFinal'] != null ? DateTime.parse(item['dataFinal']) : null,
        });
      }
      for (var item in resNotas.data) {
        DateTime f = soloFecha(DateTime.parse(item['data']));
        recordatoriosGrupo.putIfAbsent(f, () => []).add({
          'id': item['id'], 'mensaje': item['titol'], 'contenido': item['contingut'],
          'tipo': 'nota', 'color': Colors.orange, 'autor': item['creadorNom'] ?? "Usuario",
        });
      }
      notifyListeners();
    } catch (e) { debugPrint("Error datos grupo: $e"); }
  }

  Future<String?> crearGrupoEnBackend(String nombre) async {
    try {
      print("Enviando a backend: nom=$nombre (Código automático)");

      final response = await apiService.post('/grups', data: {
        "nom": nombre
      });
      print("Respuesta servidor: ${response.data}");

      await cargarGruposDesdeBackend();
      final codigoGenerado = response.data['codi'] ?? response.data['codi_acces'] ?? response.data['codigo'];

      return codigoGenerado?.toString(); // Devolvemos el código a la vista
    } on DioException catch (e) {
      print("ERROR AL CREAR GRUPO: ${e.message} - ${e.response?.data}");
      return null;
    }
  }

  Future<bool> unirseAGrupoEnBackend(String codigo) async {
    try {
      await apiService.post('/grups/join', data: {"codi_acces": codigo});
      await cargarGruposDesdeBackend();
      return true;
    } catch (e) { return false; }
  }

  Future<void> cargarDatosUsuarioYTienda(String fallbackCorreo, String fallbackNombre) async {
    try {
      final responseItems = await apiService.get('/botiga');
      final responseUser = await apiService.get('/users/me');

      itemsTienda = responseItems.data is List ? responseItems.data : [];
      puntosUsuario = responseUser.data['punts'] ?? 0;
      correoUsuario = responseUser.data['email'] ?? fallbackCorreo;
      nombreReal = responseUser.data['nom'] ?? fallbackNombre;
      apellidosReal = responseUser.data['cognoms'] ?? "";
      rachaActual = responseUser.data['racha'] ?? 0;
      notifyListeners();
    } catch (e) { debugPrint("Error cargando tienda/usuario: $e"); }

    try {
      final responseStats = await apiService.get('/users/me/stats');
      minutosTotalesEstudiados = responseStats.data['totalMinutosEstudiados'] ?? 0;
      tareasCompletadas = responseStats.data['tareasCompletadas'] ?? 0;
      rachaActual = responseStats.data['rachaActual'] ?? rachaActual;
      puntosUsuario = responseStats.data['puntosActuales'] ?? puntosUsuario;
      notifyListeners();
    } catch (e) { debugPrint("Error al cargar estadísticas: $e"); }
  }

  Future<void> cargarNotasDesdeBackend() async {
    try {
      final response = await apiService.get('/notas');
      if (response.statusCode == 200) {
        for (var item in response.data) {
          DateTime fecha = soloFecha(DateTime.parse(item['data']));
          recordatorios.putIfAbsent(fecha, () => []).add({
            'id': item['id'], 'mensaje': item['titol'], 'contenido': item['contingut'],
            'tipo': 'nota', 'color': Colors.orange, 'completada': false,
          });
        }
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> cargarRecordatoriosDesdeBackend(BuildContext context) async {
    try {
      final response = await apiService.get('/recordatoris');
      if (response.statusCode == 200) {
        recordatorios.clear();
        for (var item in response.data) {
          DateTime fI = soloFecha(DateTime.parse(item['dataHora']));
          DateTime? fF = item['dataFinal'] != null ? soloFecha(DateTime.parse(item['dataFinal'])) : null;
          final d = {'id': item['id'], 'mensaje': item['missatge'], 'tipo': 'tarea', 'color': Colors.blue, 'completada': item['completat'] ?? false, 'fechaInicial': fI, 'fechaFinal': fF, 'penalizado': false};
          recordatorios.putIfAbsent(fI, () => []).add(d);
          if (fF != null && fI != fF) recordatorios.putIfAbsent(fF, () => []).add(d);
        }
        notifyListeners();
        comprobarPenalizaciones(context);
      }
    } catch (e) {}
  }

  void comprobarPenalizaciones(BuildContext context) {
    final now = soloFecha(DateTime.now());
    int perdidos = 0;
    recordatorios.forEach((date, tasks) {
      for (var t in tasks) {
        if (t['tipo'] == 'tarea' && t['completada'] == false && t['fechaFinal'] != null && t['fechaFinal'].isBefore(now) && t['penalizado'] != true) {
          t['penalizado'] = true; perdidos += 15;
        }
      }
    });
    if (perdidos > 0) {
      puntosUsuario -= perdidos;
      if (puntosUsuario < 0) puntosUsuario = 0;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("-$perdidos pts por tareas expiradas"), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> actualizarEstadoEnBackend(Map<String, dynamic> rec, bool nuevoEstado) async {
    if (rec['id'] == null) return;
    try {
      String path = grupoSelectedId() != null
          ? '/grups/${grupoSelectedId()}/recordatoris/${rec['id']}/estat'
          : '/recordatoris/${rec['id']}/estat';
      await apiService.patch(path, data: {"completat": nuevoEstado});
      rec['completada'] = nuevoEstado;
      notifyListeners();
    } catch (e) {}
  }

  int? grupoSelectedId() => grupoSeleccionado != null ? grupoSeleccionado!['id'] : null;

  Future<bool> comprarItem(int itemId) async {
    try {
      final response = await apiService.post('/botiga/comprar/$itemId');
      if (response.statusCode == 200) {
        puntosUsuario = response.data['nuevoSaldo'] ?? puntosUsuario;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> equiparItem(int itemId) async {
    try {
      final response = await apiService.post('/inventari/equipar/$itemId');
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> desequiparItem(int itemId) async {
    try {
      final response = await apiService.post('/inventari/desequipar/$itemId');
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<dynamic> guardarEnBackend(String tipo, String mensaje, DateTime fecha, {String? contenido, DateTime? fechaFinal}) async {
    String fechaSimple = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    String iso = "${fechaSimple}T00:00:00";
    String endpoint = grupoSeleccionado != null ? (tipo == 'nota' ? '/grups/${grupoSelectedId()}/notas' : '/grups/${grupoSelectedId()}/recordatoris') : (tipo == 'nota' ? '/notas' : '/recordatoris');

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
    } catch (e) { return null; }
  }

  Future<void> enviarNotaAlBackend(String titol, String contingut) async {
    try {
      String fechaISO = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}T00:00:00";
      await apiService.post('/notas', data: {'titol': titol, 'contingut': contingut, 'data': fechaISO});
      await cargarNotasDesdeBackend();
    } catch (e) { debugPrint("Error al guardar la nota: $e"); }
  }

  // === LÓGICA DEL CRONÓMETRO / RELOJ ===

  Future<void> alternarCronometro() async {
    if (cronometroActivo) {
      _cronometro?.cancel();
      animationController.stop();
      await reproductorMusica.pause();
      cronometroActivo = false;
      notifyListeners();
    } else {
      if ((tecnicaSeleccionada == 1 || tecnicaSeleccionada == 2) && tiempoRestante == Duration.zero) {
        tiempoRestante = Duration(minutes: tecnicaSeleccionada == 1 ? 25 : estudioPersonalizado);
        estaEnFaseEstudio = true;
      } else if (tecnicaSeleccionada == 0 && esTemporizador && tiempoRestante == Duration.zero) {
        tiempoRestante = Duration(hours: tempHoras, minutes: tempMinutos);
      }

      if ((esTemporizador || (tecnicaSeleccionada != 0 && tecnicaSeleccionada != 3)) && tiempoRestante <= Duration.zero) return;

      cronometroActivo = true;
      animationController.repeat();
      notifyListeners();

      if (musicaEstaEquipada() && estaEnFaseEstudio && sonidoHabilitado) {
        try {
          await reproductorMusica.setReleaseMode(ReleaseMode.loop);
          await reproductorMusica.play(AssetSource('lofi.mp3'));
        } catch (e) { debugPrint("Error audio: $e"); }
      }

      _cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (esTemporizador || (tecnicaSeleccionada != 0 && tecnicaSeleccionada != 3)) {
          tiempoTranscurrido += const Duration(seconds: 1);
          tiempoRestante -= const Duration(seconds: 1);
          if (tiempoRestante <= Duration.zero) {
            tiempoRestante = Duration.zero;
            if (tecnicaSeleccionada != 0) {
              cambiarFaseTecnica();
            } else {
              _cronometro?.cancel();
              cronometroActivo = false;
              animationController.stop();
              reproductorMusica.pause();
            }
          }
        } else if (tecnicaSeleccionada == 3) { // Flowtime
          if (estaEnFaseEstudio) {
            tiempoTranscurrido += const Duration(seconds: 1);
          } else {
            tiempoRestante -= const Duration(seconds: 1);
            if (tiempoRestante <= Duration.zero) {
              tiempoRestante = Duration.zero;
              estaEnFaseEstudio = true;
              tiempoTranscurrido = Duration.zero;
              if (musicaEstaEquipada() && sonidoHabilitado) reproductorMusica.resume();
              // La notificación de la fase se gestionará con un callback desde la vista
            }
          }
        } else { // Modo libre
          if (estaEnFaseEstudio) {
            tiempoTranscurrido += const Duration(seconds: 1);
          } else {
            tiempoDescansoLibre += const Duration(seconds: 1);
          }
        }
        notifyListeners(); // Repinta en cada segundo
      });
    }
  }

  void cambiarFaseTecnica() {
    estaEnFaseEstudio = !estaEnFaseEstudio;
    reproductorMusica.pause();
    int mins = tecnicaSeleccionada == 1 ? (estaEnFaseEstudio ? 25 : 5) : (estaEnFaseEstudio ? estudioPersonalizado : descansoPersonalizado);
    tiempoRestante = Duration(minutes: mins);
    notifyListeners();
  }

  void alternarFaseLibre() {
    if (tecnicaSeleccionada == 3) { // Flowtime
      if (estaEnFaseEstudio) {
        int studySeconds = tiempoTranscurrido.inSeconds;
        tiempoRestante = Duration(seconds: (studySeconds * 0.4).round());
        estaEnFaseEstudio = false;
        reproductorMusica.pause();
      } else {
        estaEnFaseEstudio = true;
        tiempoTranscurrido = Duration.zero;
        if (musicaEstaEquipada() && sonidoHabilitado) reproductorMusica.resume();
      }
    } else {
      estaEnFaseEstudio = !estaEnFaseEstudio;
      if (estaEnFaseEstudio && musicaEstaEquipada() && sonidoHabilitado) {
        reproductorMusica.resume();
      } else {
        reproductorMusica.pause();
      }
    }
    notifyListeners();
  }

  void resetearCronometro() {
    _cronometro?.cancel();
    animationController.stop();
    animationController.value = 0;
    reproductorMusica.stop();
    tiempoTranscurrido = Duration.zero;
    tiempoDescansoLibre = Duration.zero;
    cronometroActivo = false;
    selectedRecordatoriId = null;
    tiempoRestante = Duration.zero;
    estaEnFaseEstudio = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> finalizarSesionBackend() async {
    int minutos = tiempoTranscurrido.inMinutes;
    if (minutos == 0 && tiempoTranscurrido.inSeconds > 0) minutos = 1;

    if (minutos <= 0) return null;

    try {
      final data = {
        "minuts": minutos,
        if (selectedRecordatoriId != null) "recordatoriId": selectedRecordatoriId,
      };

      final response = await apiService.post('/sessions', data: data);
      if (response.statusCode == 200) {
        reproductorMusica.stop();
        puntosUsuario = response.data['nuevoSaldo'] ?? puntosUsuario;
        notifyListeners();
        return {
          "minutos": minutos,
          "puntosGanados": response.data['puntosGanados'] ?? 0,
          "nuevoSaldo": puntosUsuario
        };
      }
      return null;
    } catch (e) { return null; }
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    reproductorMusica.dispose();
    super.dispose();
  }
}