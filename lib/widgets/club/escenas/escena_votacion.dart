import 'package:flutter/material.dart';

class EscenaVotacion extends StatelessWidget {
  final int totalCandidatas;

  const EscenaVotacion({super.key, required this.totalCandidatas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "$totalCandidatas historias esperan convertirse\n"
          "en la próxima lectura del club.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          "Cada voto acerca el desenlace.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
