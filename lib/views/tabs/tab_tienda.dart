import 'package:flutter/material.dart';
import 'package:focusup/viewmodels/main_viewmodel.dart';
import '../widgets/group_ranking.dart';

class TabTienda extends StatelessWidget {
  final MainViewModel viewModel;

  const TabTienda({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Si estamos dentro de un grupo, anulamos la tienda y mostramos el ranking
    if (viewModel.grupoSeleccionado != null) {
      return GroupRanking(members: viewModel.grupoSeleccionado!['membres'] ?? []);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // cabezera de la tienda (puntos)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber.withValues(alpha: 0.1),
                  radius: 25,
                  child: const Icon(Icons.stars, color: Colors.amber, size: 30),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Puntos Disponibles",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${viewModel.puntosUsuario}",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.shopping_bag_outlined, color: Colors.blueAccent.withValues(alpha: 0.3), size: 30),
              ],
            ),
          ),
        ),

        // cuadricula de objetos
        Expanded(
          child: viewModel.itemsTienda.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: viewModel.itemsTienda.length,
            itemBuilder: (context, index) {
              final item = viewModel.itemsTienda[index];
              final bool comprat = item['comprat'] ?? false;
              final bool equipat = item['equipat'] ?? false;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Stack(
                  children: [
                    //Información del Item
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.redeem, size: 40, color: Colors.blue),
                          const SizedBox(height: 8),
                          Text(item['nom'] ?? 'Item', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),

                          Text(comprat ? "¡Adquirido!" : "${item['preu']} pts",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: comprat ? Colors.green : Colors.blue, fontWeight: FontWeight.w600, fontSize: 11)
                          ),
                          const SizedBox(height: 8),

                          // Botón de compra
                          if (!comprat)
                            ElevatedButton(
                              onPressed: () => _procesarCompra(context, item['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Comprar", style: TextStyle(fontSize: 11)),
                            )
                          else
                            const SizedBox(height: 30), // Espacio para mantener proporción
                        ],
                      ),
                    ),

                    //Botón de Equipar/Desequipar
                    if (comprat)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(
                            equipat ? Icons.check_circle : Icons.circle_outlined,
                            color: equipat ? Colors.orange : Colors.grey[400],
                            size: 26,
                          ),
                          onPressed: () {
                            if (equipat) {
                              _procesarDesequipar(context, item['id']);
                            } else {
                              _procesarEquipar(context, item['id']);
                            }
                          },
                          tooltip: equipat ? "Desequipar" : "Equipar",
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  //feedback de compra y equipar/desequipar
  Future<void> _procesarCompra(BuildContext context, int itemId) async {
    bool exito = await viewModel.comprarItem(itemId);
    if (context.mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Compra realizada con éxito!"), backgroundColor: Colors.green));
        // Recargamos los datos para ver el nuevo saldo y el objeto comprado
        viewModel.cargarDatosUsuarioYTienda(viewModel.correoUsuario, viewModel.nombreReal);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error en la compra. Verifica tu saldo."), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _procesarEquipar(BuildContext context, int itemId) async {
    bool exito = await viewModel.equiparItem(itemId);
    if (context.mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Objeto equipado!"), backgroundColor: Colors.blue));
        await viewModel.cargarDatosUsuarioYTienda(viewModel.correoUsuario, viewModel.nombreReal);

        // Lógica de audio: si se equipa música estudiando, arranca sola
        if (viewModel.cronometroActivo && viewModel.estaEnFaseEstudio && viewModel.musicaEstaEquipada() && viewModel.sonidoHabilitado) {
          viewModel.reproductorMusica.resume();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al equipar el objeto."), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _procesarDesequipar(BuildContext context, int itemId) async {
    bool exito = await viewModel.desequiparItem(itemId);
    if (context.mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Objeto desequipado"), backgroundColor: Colors.orange));
        await viewModel.cargarDatosUsuarioYTienda(viewModel.correoUsuario, viewModel.nombreReal);

        // Lógica de audio: si quitamos la música, se silencia
        if (!viewModel.musicaEstaEquipada()) {
          viewModel.reproductorMusica.pause();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al desequipar el objeto."), backgroundColor: Colors.red));
      }
    }
  }
}