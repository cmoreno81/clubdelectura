import 'package:flutter/material.dart';

class ComentarioInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onEnviar;

  const ComentarioInput({
    super.key,
    required this.controller,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "¿Qué te ha parecido este capítulo?",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: onEnviar, child: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
