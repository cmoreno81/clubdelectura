import 'package:flutter/material.dart';

class FinalizarLibroDialog extends StatefulWidget {
  const FinalizarLibroDialog({super.key});

  @override
  State<FinalizarLibroDialog> createState() => _FinalizarLibroDialogState();
}

class _FinalizarLibroDialogState extends State<FinalizarLibroDialog> {
  String? valoracion;

  final controller = TextEditingController();

  final valoraciones = const [
    "⭐️⭐️⭐️⭐️⭐️",
    "⭐️⭐️⭐️⭐️",
    "⭐️⭐️⭐️",
    "⭐️⭐️",
    "⭐️",
    "😞",
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("⭐ Finalizar lectura"),

      content: SizedBox(
        width: 420,

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "¿Qué valoración le das al libro?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,

                children: valoraciones.map((v) {
                  final seleccionada = valoracion == v;

                  return ChoiceChip(
                    label: Text(v, style: const TextStyle(fontSize: 18)),

                    selected: seleccionada,

                    onSelected: (_) {
                      setState(() {
                        valoracion = v;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              const Text(
                "💭 Tu reseña (opcional)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 9,
                maxLength: 5000,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                scrollPadding: const EdgeInsets.only(bottom: 140),

                decoration: InputDecoration(
                  hintText:
                      '¿Qué te ha parecido el libro?\n\n'
                      'Esta reseña aparecerá en la ficha del libro.',
                  filled: true,
                  fillColor: const Color(0xFFF7F1FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE1D4F5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFF6F4DBF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancelar"),
        ),

        FilledButton.icon(
          onPressed: valoracion == null
              ? null
              : () {
                  Navigator.pop(context, {
                    "valoracion": valoracion!,

                    "reflexion": controller.text.trim(),
                  });
                },

          icon: const Icon(Icons.check),

          label: const Text("Finalizar"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
