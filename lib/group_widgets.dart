import 'package:flutter/material.dart';

class GroupRanking extends StatelessWidget {
  final List<dynamic> members;

  const GroupRanking({Key? key, required this.members}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ordenamos los miembros por puntos de mayor a menor
    final sortedMembers = List.from(members);
    sortedMembers.sort((a, b) => (b['punts'] ?? 0).compareTo(a['punts'] ?? 0));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Clasificación del Grupo",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedMembers.length,
            itemBuilder: (context, index) {
              final member = sortedMembers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(index),
                  child: Text("${index + 1}", style: const TextStyle(color: Colors.white)),
                ),
                title: Text(member['username'] ?? "Usuario"),
                trailing: Text("${member['punts'] ?? 0} pts", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber; // Oro
    if (index == 1) return Colors.grey;  // Plata
    if (index == 2) return Colors.brown; // Bronce
    return Colors.blueAccent;
  }
}
