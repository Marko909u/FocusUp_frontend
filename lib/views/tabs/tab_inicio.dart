import 'package:flutter/material.dart';
import 'package:focusup/viewmodels/main_viewmodel.dart';

class TabInicio extends StatelessWidget {
  final MainViewModel viewModel;
  final String nombreUsuarioOriginal;

  const TabInicio({
    super.key,
    required this.viewModel,
    required this.nombreUsuarioOriginal,
  });

  @override
  Widget build(BuildContext context) {
    final fA = viewModel.soloFecha(viewModel.fechaSeleccionada);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final esMovil = MediaQuery.of(context).size.width < 600;

    // Obtenemos la lista de tareas del día seleccionado
    final lista = viewModel.grupoSeleccionado != null
        ? viewModel.recordatoriosGrupo[fA] ?? []
        : viewModel.recordatorios[fA] ?? [];

    // Decidimos qué nombre mostrar
    final nombreMostrar = viewModel.nombreReal.trim().isNotEmpty
        ? viewModel.nombreReal
        : nombreUsuarioOriginal;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('¡Bienvenido/a, $nombreMostrar!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.blue[200] : Colors.blueAccent)
            ),
            const SizedBox(height: 10),

            Text(viewModel.grupoSeleccionado != null ? 'Calendario de ${viewModel.grupoSeleccionado!['nom']}:' : 'Calendario personal:',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            esMovil
            // MÓVIL
                ? Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: _boxDecoration(context, isDark),
                  child: _calendarioPersonalizado(context, isDark),
                ),
                if (viewModel.grupoSeleccionado != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton.icon(
                      onPressed: () => viewModel.seleccionarGrupo(null),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Volver al calendario personal"),
                    ),
                  ),
                if (viewModel.grupoSeleccionado == null && viewModel.grupos.isNotEmpty)
                  _panelGruposMovil(isDark),
              ],
            )
            //WEB/DESKTOP
                : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 950),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 700),
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: _boxDecoration(context, isDark),
                            child: _calendarioPersonalizado(context, isDark),
                          ),
                          if (viewModel.grupoSeleccionado != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: TextButton.icon(
                                onPressed: () => viewModel.seleccionarGrupo(null),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text("Volver al calendario personal"),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (viewModel.grupoSeleccionado == null && viewModel.grupos.isNotEmpty)
                      _panelGruposEscritorio(isDark, context),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 35),

            // LISTA DE TAREAS DEL DÍA
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
                            _confirmarDeshacerTarea(context, rec);
                          } else {
                            viewModel.actualizarEstadoEnBackend(rec, value ?? false);
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

  BoxDecoration _boxDecoration(BuildContext context, bool isDark) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black12, blurRadius: 10)],
      border: Border.all(color: isDark ? Colors.blueGrey[800]! : Colors.blue[100]!),
    );
  }

  Widget _calendarioPersonalizado(BuildContext context, bool isDark) {
    DateTime pDM = DateTime(viewModel.fechaSeleccionada.year, viewModel.fechaSeleccionada.month, 1);
    int dEM = DateTime(viewModel.fechaSeleccionada.year, viewModel.fechaSeleccionada.month + 1, 0).day;
    int desfase = pDM.weekday - 1;

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.blue, size: 20),
              onPressed: () => viewModel.cambiarFechaSeleccionada(DateTime(viewModel.fechaSeleccionada.year, viewModel.fechaSeleccionada.month - 1, 1))
          ),
          Text("${viewModel.nombreMes(viewModel.fechaSeleccionada.month)} ${viewModel.fechaSeleccionada.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.blue, size: 20),
              onPressed: () => viewModel.cambiarFechaSeleccionada(DateTime(viewModel.fechaSeleccionada.year, viewModel.fechaSeleccionada.month + 1, 1))
          ),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ["L", "M", "X", "J", "V", "S", "D"].map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))).toList()),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dEM + desfase,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.85),
          itemBuilder: (context, index) {
            if (index < desfase) return const SizedBox();
            int dia = index - desfase + 1;
            DateTime fDia = DateTime(viewModel.fechaSeleccionada.year, viewModel.fechaSeleccionada.month, dia);
            bool sel = viewModel.soloFecha(viewModel.fechaSeleccionada) == viewModel.soloFecha(fDia);
            final recs = viewModel.grupoSeleccionado != null ? viewModel.recordatoriosGrupo[viewModel.soloFecha(fDia)] ?? [] : viewModel.recordatorios[viewModel.soloFecha(fDia)] ?? [];

            return GestureDetector(
              onTap: () => viewModel.cambiarFechaSeleccionada(fDia),
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

  Widget _panelGruposMovil(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, size: 18, color: isDark ? Colors.blue[200] : Colors.blue[700]),
              const SizedBox(width: 5),
              const Text("Mis grupos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: viewModel.grupos.length,
              itemBuilder: (context, index) {
                final g = viewModel.grupos[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ActionChip(
                    backgroundColor: isDark ? Colors.blueGrey[900] : Colors.blue[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? Colors.blueGrey[700]! : Colors.blue[200]!)),
                    label: Text(g['nom'], style: TextStyle(color: isDark ? Colors.blue[200] : Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => viewModel.seleccionarGrupo(g),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelGruposEscritorio(bool isDark, BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey[900] : Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.blueGrey[700]! : Colors.blue[100]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups, size: 18, color: isDark ? Colors.blue[200] : Colors.blue[700]),
              const SizedBox(width: 6),
              const Text("Mis grupos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 20),
          ...viewModel.grupos.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => viewModel.seleccionarGrupo(g),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Text(
                  g['nom'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.blue[200] : Colors.blue[800]),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  void _confirmarDeshacerTarea(BuildContext context, Map<String, dynamic> tarea) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
          title: const Text("Deshacer tarea"),
          content: const Text("¿Deseas deshacer la tarea completada?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
            TextButton(
                onPressed: () {
                  // Le decimos al ViewModel que la pase a false en el backend
                  viewModel.actualizarEstadoEnBackend(tarea, false);
                  Navigator.pop(c);
                },
                child: const Text("Sí, deshacer")
            ),
          ]
      ),
    );
  }
}