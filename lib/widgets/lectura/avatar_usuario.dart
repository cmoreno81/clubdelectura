import 'package:flutter/material.dart';

class AvatarUsuario extends StatelessWidget {
  final String nombre;

  const AvatarUsuario({super.key, required this.nombre});

  Color _color() {
    final colores = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
      Colors.indigo,
    ];

    return colores[nombre.hashCode.abs() % colores.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: _color(),
      child: Text(
        nombre.isEmpty ? "?" : nombre[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
