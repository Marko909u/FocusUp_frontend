import 'package:flutter/material.dart';

class GroupRanking extends StatelessWidget {
  final List<dynamic> members;

  const GroupRanking({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    final clasificacion = List<dynamic>.from(members)
      ..sort((a, b) => (b['punts'] ?? 0).compareTo(a['punts'] ?? 0));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (clasificacion.isEmpty) {
      return const Center(child: Text("Aún no hay miembros en este grupo", style: TextStyle(color: Colors.grey)));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "Clasificación del Grupo",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 15),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
                border: Border.all(color: isDark ? Colors.blueGrey[800]! : Colors.blue[100]!),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blueGrey[900] : Colors.blue[50],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 40, child: Text("#", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                        Expanded(child: Text("Usuario", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                        Text("Puntos", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue), textAlign: TextAlign.right),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: clasificacion.length,
                      itemBuilder: (context, index) {
                        final member = clasificacion[index];
                        final rank = index + 1;

                        final rowColor = index % 2 == 0
                            ? Colors.transparent
                            : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02));

                        IconData? rankIcon;
                        Color? rankColor;
                        if (rank == 1) { rankIcon = Icons.emoji_events; rankColor = Colors.amber; }
                        else if (rank == 2) { rankIcon = Icons.emoji_events; rankColor = Colors.grey[400]; }
                        else if (rank == 3) { rankIcon = Icons.emoji_events; rankColor = Colors.brown[300]; }

                        return Container(
                          color: rowColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: rankIcon != null
                                    ? Row(children: [Text("$rank", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 2), Icon(rankIcon, size: 16, color: rankColor)])
                                    : Text("$rank", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                              Expanded(
                                child: Text(
                                  member['username'] ?? 'Usuario',
                                  style: TextStyle(fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: Text("${member['punts'] ?? 0} pts", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}