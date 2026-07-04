import 'package:flutter/material.dart';

class CapituloTile extends StatelessWidget {
  final String titulo;
  final VoidCallback onTap;

  const CapituloTile({super.key, required this.titulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.forum_outlined),
        title: Text(titulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
