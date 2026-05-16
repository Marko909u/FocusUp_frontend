import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusup/viewmodels/main_viewmodel.dart';
import 'package:focusup/core/token_storage.dart';
import '../../main.dart';
import 'package:focusup/viewmodels/settings.dart';

class TabPerfil extends StatelessWidget {
  final MainViewModel viewModel;
  final String nombreUsuarioOriginal;

  const TabPerfil({
    super.key,
    required this.viewModel,
    required this.nombreUsuarioOriginal,
  });

  @override
  Widget build(BuildContext context) {
    // Calculamos el nombre a mostrar combinando nombre y apellidos
    final nombreCompleto = "${viewModel.nombreReal} ${viewModel.apellidosReal}".trim();
    final nombreMostrar = nombreCompleto.isNotEmpty ? nombreCompleto : nombreUsuarioOriginal;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Column(
          children: [
            // Cabezera perfil
            const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 80, color: Colors.white)
            ),
            const SizedBox(height: 20),
            Text(
                nombreMostrar,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
            ),
            Text(
                viewModel.correoUsuario,
                style: const TextStyle(fontSize: 16, color: Colors.grey)
            ),

            const SizedBox(height: 30),

            // Estadísticas
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Tus Estadísticas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tarjetaEstadistica("Minutos\nEstudiados", "${viewModel.minutosTotalesEstudiados}", Icons.timer, Colors.blue),
                _tarjetaEstadistica("Tareas\nCompletadas", "${viewModel.tareasCompletadas}", Icons.task_alt, Colors.green),
                _tarjetaEstadistica("Racha\nActual", "${viewModel.rachaActual}", Icons.local_fire_department, Colors.orange),
              ],
            ),

            const SizedBox(height: 40),

            //Menu de opciones
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  ListTile(
                      leading: const Icon(Icons.settings, color: Colors.blue),
                      title: const Text('Configuración'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _abrirAjustes(context)
                  ),
                  const Divider(height: 1),
                  ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Cerrar Sesión'),
                      onTap: () => _cerrarSesion(context)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Widgets de Estadísticas

  Widget _tarjetaEstadistica(String titulo, String valor, IconData icono, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(icono, color: color, size: 32),
              const SizedBox(height: 8),
              Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirAjustes(BuildContext context) async {

    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));

    // Al volver de ajustes, leemos SharedPreferences para ver si apagó la música
    final prefs = await SharedPreferences.getInstance();
    bool sonido = prefs.getBool('ajuste_sonido') ?? true;
    viewModel.aplicarVolumen(sonido);
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await TokenStorage.deleteToken();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => const MenuPrincipal()),
        (route) => false
      );
    }
  }
}