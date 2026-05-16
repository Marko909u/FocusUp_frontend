import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusup/viewmodels/main_viewmodel.dart';
import 'tabs/tab_inicio.dart';
import 'tabs/tab_reloj.dart';
import 'tabs/tab_tienda.dart';
import 'tabs/tab_perfil.dart';

class PaginaPrincipal extends StatefulWidget {
  final String nombreUsuario;
  final String correoUsuario;

  const PaginaPrincipal({
    super.key,
    required this.nombreUsuario,
    required this.correoUsuario,
  });

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> with SingleTickerProviderStateMixin {

  late final MainViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MainViewModel();

    //Inicializamos el controlador de animaciones del reloj y se lo pasamos al ViewModel
    _viewModel.animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    //Cargamos los datos iniciales
    _viewModel.correoUsuario = widget.correoUsuario;
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    //Leemos las preferencias de sonido
    final prefs = await SharedPreferences.getInstance();
    bool sonidoHabilitado = prefs.getBool('ajuste_sonido') ?? true;
    _viewModel.aplicarVolumen(sonidoHabilitado);

    //Disparamos las peticiones al backend
    await _viewModel.cargarRecordatoriosDesdeBackend(context);
    await _viewModel.cargarNotasDesdeBackend();
    await _viewModel.cargarDatosUsuarioYTienda(widget.correoUsuario, widget.nombreUsuario);
    await _viewModel.cargarGruposDesdeBackend();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FocusUp'),
            automaticallyImplyLeading: false,
            actions: [
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text('${_viewModel.puntosUsuario}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('${_viewModel.rachaActual}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                ],
              ),
            ],
          ),

          //Inyectamos el ViewModel en la pestaña correspondiente
          body: [
            TabInicio(viewModel: _viewModel, nombreUsuarioOriginal: widget.nombreUsuario),
            TabReloj(viewModel: _viewModel),
            TabTienda(viewModel: _viewModel),
            TabPerfil(viewModel: _viewModel, nombreUsuarioOriginal: widget.nombreUsuario),
          ][_viewModel.indiceActual],

          floatingActionButton: FloatingActionButton(
              onPressed: () => _mostrarOpcionesFab(context),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add)
          ),

          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.blue,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.blue[100],
            type: BottomNavigationBarType.fixed,
            currentIndex: _viewModel.indiceActual,
            onTap: (index) => _viewModel.setIndice(index),
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              const BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reloj'),
              BottomNavigationBarItem(
                  icon: Icon(_viewModel.grupoSeleccionado != null ? Icons.leaderboard : Icons.shopping_cart),
                  label: _viewModel.grupoSeleccionado != null ? 'Ranking' : 'Tienda'
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        );
      },
    );
  }

  void _mostrarOpcionesFab(BuildContext context) {
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
    String nombreGrupo = "";

    showDialog(context: context, builder: (c) => AlertDialog(
        title: const Text('Crear Nuevo Grupo'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  decoration: const InputDecoration(labelText: 'Nombre del Grupo'),
                  onChanged: (v) => nombreGrupo = v
              ),
            ]
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () async {
                if (nombreGrupo.isNotEmpty) {
                  Navigator.pop(c);
                  String? codigoGenerado = await _viewModel.crearGrupoEnBackend(nombreGrupo);

                  if (codigoGenerado != null && context.mounted) {
                    _mostrarDialogoCodigoGenerado(nombreGrupo, codigoGenerado);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Error al crear el grupo"),
                        backgroundColor: Colors.red
                    ));
                  }
                }
              },
              child: const Text('Crear')
          )
        ]
    ));
  }


  void _mostrarDialogoCodigoGenerado(String nombre, String codigo) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¡Grupo Creado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('El grupo "$nombre" se ha creado con éxito.'),
            const SizedBox(height: 15),
            const Text('Comparte este código con tus amigos para que puedan unirse:',
                style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue),
              ),
              child: SelectableText(
                codigo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Entendido')
          )
        ],
      ),
    );
  }

  void _mostrarDialogoUnirseGrupo() {
    String cod = "";
    showDialog(context: context, builder: (c) => AlertDialog(
        title: const Text('Unirse a Grupo'),
        content: TextField(decoration: const InputDecoration(labelText: 'Código del Grupo'), onChanged: (v) => cod = v),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            if (cod.isNotEmpty) {
              bool exito = await _viewModel.unirseAGrupoEnBackend(cod);
              if (context.mounted) {
                Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(exito ? "¡Unido con éxito!" : "Código inválido"),
                    backgroundColor: exito ? Colors.green : Colors.red
                ));
              }
            }
          }, child: const Text('Unirse'))
        ]
    ));
  }

  void _mostrarDialogoFormulario(String tipo) {
    String tit = ""; String cont = ""; String msg = ""; Color col = Colors.blue;
    DateTime fI = _viewModel.fechaSeleccionada;
    DateTime fF = _viewModel.fechaSeleccionada.add(const Duration(days: 1));

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
              final res = await _viewModel.guardarEnBackend(tipo, tipo == 'nota' ? tit : msg, fI, contenido: cont, fechaFinal: tipo == 'tarea' ? fF : null);
              if (res != null) {
                // Actualizamos la lista local y avisamos a la vista
                final f = _viewModel.soloFecha(fI);
                final nuevo = {'id': (res is Map) ? res['id'] : null, 'mensaje': tipo == 'nota' ? tit : msg, 'contenido': cont, 'color': col, 'tipo': tipo, 'completada': false, 'fechaInicial': f, 'fechaFinal': fF, 'autor': widget.nombreUsuario};

                if (_viewModel.grupoSeleccionado != null) {
                  _viewModel.recordatoriosGrupo.putIfAbsent(f, () => []).add(nuevo);
                } else {
                  _viewModel.recordatorios.putIfAbsent(f, () => []).add(nuevo);
                }


                // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                _viewModel.notifyListeners();

                if (context.mounted) Navigator.pop(context);
              }
            }
          }, child: const Text('Guardar')),
        ],
      )),
    );
  }
}