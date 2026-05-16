import 'package:flutter/material.dart';
import 'package:focusup/viewmodels/main_viewmodel.dart';
import '../widgets/wave_painter.dart';

class TabReloj extends StatelessWidget {
  final MainViewModel viewModel;

  const TabReloj({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    //Preparamos la lista de tareas disponibles para asignar al reloj
    final recordatoriosActuales = viewModel.grupoSeleccionado != null
        ? viewModel.recordatoriosGrupo
        : viewModel.recordatorios;

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

            // tecnicas de estudio
            Wrap(
              spacing: 4,
              alignment: WrapAlignment.center,
              children: [
                ChoiceChip(
                    label: const Text("Ninguna", style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    selected: viewModel.tecnicaSeleccionada == 0,
                    onSelected: (v) { if (!viewModel.cronometroActivo) viewModel.setTecnicaSeleccionada(0); }
                ),
                ChoiceChip(
                    label: const Text("Pomodoro", style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    selected: viewModel.tecnicaSeleccionada == 1,
                    onSelected: (v) { if (!viewModel.cronometroActivo) viewModel.setTecnicaSeleccionada(1); }
                ),
                ChoiceChip(
                    label: const Text("Personalizada", style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    selected: viewModel.tecnicaSeleccionada == 2,
                    onSelected: (v) { if (!viewModel.cronometroActivo) viewModel.setTecnicaSeleccionada(2); }
                ),
                ChoiceChip(
                    label: const Text("Flowtime", style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    selected: viewModel.tecnicaSeleccionada == 3,
                    onSelected: (v) { if (!viewModel.cronometroActivo) viewModel.setTecnicaSeleccionada(3); }
                ),
              ],
            ),
            const SizedBox(height: 20),

            // selector cronometro/temporizador
            if (viewModel.tecnicaSeleccionada == 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                      label: const Text("Cronómetro"),
                      selected: !viewModel.esTemporizador,
                      onSelected: (v) { if (!viewModel.cronometroActivo) viewModel.setEsTemporizador(false); }
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                      label: const Text("Temporizador"),
                      selected: viewModel.esTemporizador,
                      onSelected: (v) { if (!viewModel.cronometroActivo) viewModel.setEsTemporizador(true); }
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // selector tarea
            if (!viewModel.cronometroActivo) ...[
              const Text("Trabajar en:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: viewModel.selectedRecordatoriId,
                hint: const Text("Selecciona una tarea"),
                onChanged: (int? newValue) => viewModel.setRecordatoriId(newValue),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text("Sin tarea asignada")),
                  ...todasLasTareas.map((tarea) => DropdownMenuItem<int>(
                    value: tarea['id'],
                    child: Text(tarea['mensaje']),
                  )),
                ],
              ),
            ] else if (viewModel.selectedRecordatoriId != null) ...[
              Text(
                "Tarea actual: ${todasLasTareas.firstWhere((t) => t['id'] == viewModel.selectedRecordatoriId, orElse: () => {'mensaje': '...' })['mensaje']}",
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
              ),
            ],

            const SizedBox(height: 20),

            // configuracion de tiempo personalizable
            if (viewModel.tecnicaSeleccionada == 2 && !viewModel.cronometroActivo && viewModel.tiempoTranscurrido == Duration.zero)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text("Estudio (m)"),
                      DropdownButton<int>(
                        value: viewModel.estudioPersonalizado,
                        items: [15, 20, 25, 30, 45, 50, 60].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
                        onChanged: (v) => viewModel.setEstudioPersonalizado(v!),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      const Text("Descanso (m)"),
                      DropdownButton<int>(
                        value: viewModel.descansoPersonalizado,
                        items: [5, 10, 15, 20].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
                        onChanged: (v) => viewModel.setDescansoPersonalizado(v!),
                      ),
                    ],
                  ),
                ],
              )
            else if (viewModel.tecnicaSeleccionada == 0 && viewModel.esTemporizador && !viewModel.cronometroActivo && viewModel.tiempoTranscurrido == Duration.zero)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text("Horas"),
                      DropdownButton<int>(
                        value: viewModel.tempHoras,
                        items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("$i h"))),
                        onChanged: (v) => viewModel.setTempHoras(v!),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      const Text("Minutos"),
                      DropdownButton<int>(
                        value: viewModel.tempMinutos,
                        items: List.generate(60, (i) => DropdownMenuItem(value: i, child: Text("$i m"))),
                        onChanged: (v) => viewModel.setTempMinutos(v!),
                      ),
                    ],
                  ),
                ],
              ),

            if (viewModel.tecnicaSeleccionada != 0 || (viewModel.tecnicaSeleccionada == 0 && !viewModel.esTemporizador && (viewModel.cronometroActivo || viewModel.tiempoTranscurrido > Duration.zero || viewModel.tiempoDescansoLibre > Duration.zero)))
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(viewModel.estaEnFaseEstudio ? "FASE: ESTUDIO" : "FASE: DESCANSO",
                      style: TextStyle(fontWeight: FontWeight.bold, color: viewModel.estaEnFaseEstudio ? Colors.red : Colors.green)
                  )
              ),

            Text(
                (viewModel.esTemporizador || (viewModel.tecnicaSeleccionada != 0 && viewModel.tecnicaSeleccionada != 3))
                    ? (viewModel.cronometroActivo || viewModel.tiempoTranscurrido > Duration.zero ? viewModel.formatearTiempo(viewModel.tiempoRestante) : viewModel.formatearTiempo(Duration(hours: viewModel.tempHoras, minutes: viewModel.tecnicaSeleccionada == 1 ? 25 : (viewModel.tecnicaSeleccionada == 2 ? viewModel.estudioPersonalizado : viewModel.tempMinutos))))
                    : (viewModel.tecnicaSeleccionada == 3)
                    ? (viewModel.estaEnFaseEstudio ? viewModel.formatearTiempo(viewModel.tiempoTranscurrido) : viewModel.formatearTiempo(viewModel.tiempoRestante))
                    : (viewModel.estaEnFaseEstudio ? viewModel.formatearTiempo(viewModel.tiempoTranscurrido) : viewModel.formatearTiempo(viewModel.tiempoDescansoLibre)),
                style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold, fontFamily: 'monospace')
            ),

            // animacion cronometro
            Container(
              height: 40, width: 200, margin: const EdgeInsets.symmetric(vertical: 10),
              child: AnimatedBuilder(
                animation: viewModel.animationController,
                builder: (context, child) => CustomPaint(painter: WavePainter(viewModel.animationController.value, viewModel.cronometroActivo)),
              ),
            ),

            const SizedBox(height: 40),

            // botones de accion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                    onPressed: viewModel.alternarCronometro,
                    icon: Icon(viewModel.cronometroActivo ? Icons.pause : Icons.play_arrow),
                    label: Text(viewModel.cronometroActivo ? 'Parar' : 'Iniciar'),
                    style: ElevatedButton.styleFrom(backgroundColor: viewModel.cronometroActivo ? Colors.orange : Colors.green, foregroundColor: Colors.white)
                ),
                const SizedBox(width: 10),

                if ((viewModel.tecnicaSeleccionada == 0 || viewModel.tecnicaSeleccionada == 3) && !viewModel.esTemporizador && viewModel.cronometroActivo)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ElevatedButton.icon(
                      onPressed: viewModel.alternarFaseLibre,
                      icon: Icon(viewModel.estaEnFaseEstudio ? Icons.coffee : Icons.menu_book),
                      label: Text(viewModel.estaEnFaseEstudio ? 'Descansar' : 'Estudiar'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: viewModel.estaEnFaseEstudio ? Colors.purple : Colors.blueAccent,
                          foregroundColor: Colors.white
                      ),
                    ),
                  ),

                ElevatedButton.icon(
                    onPressed: () => _procesarFinalizarSesion(context),
                    icon: const Icon(Icons.save),
                    label: const Text('Finalizar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white)
                ),
                const SizedBox(width: 10),

                ElevatedButton.icon(
                    onPressed: viewModel.resetearCronometro,
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

  // pop-ups al acabar la sesión de estudio

  Future<void> _procesarFinalizarSesion(BuildContext context) async {
    int minutos = viewModel.tiempoTranscurrido.inMinutes;
    if (minutos == 0 && viewModel.tiempoTranscurrido.inSeconds > 0) minutos = 1;

    if (minutos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mínimo 1 minuto para guardar sesión")));
      return;
    }
    final resultado = await viewModel.finalizarSesionBackend();

    if (resultado != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Éxito! Ganaste ${resultado['puntosGanados']} puntos. Nuevo saldo: ${resultado['nuevoSaldo']}"),
          backgroundColor: Colors.green,
        ),
      );

      viewModel.resetearCronometro();
      if (viewModel.grupoSeleccionado != null) {
        viewModel.cargarDatosGrupo(viewModel.grupoSeleccionado!['id']);
      } else {
        viewModel.cargarRecordatoriosDesdeBackend(context);
      }
      viewModel.cargarDatosUsuarioYTienda(viewModel.correoUsuario, viewModel.nombreReal);

      _mostrarPopupNuevaNota(context, resultado['minutos'], resultado['puntosGanados']);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar la sesión en el servidor")));
    }
  }

  Future<void> _mostrarPopupNuevaNota(BuildContext context, int mins, int pts) async {
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar Nota'),
              onPressed: () {
                if (tC.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  viewModel.enviarNotaAlBackend(tC.text, cC.text);
                }
              },
            ),
          ],
        );
      },
    );
  }
}