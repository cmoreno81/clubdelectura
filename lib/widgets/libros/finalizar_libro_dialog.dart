import 'package:flutter/material.dart';
import '../common/club_rating_selector.dart';

class FinalizarLibroDialog extends StatefulWidget {
  const FinalizarLibroDialog({super.key});

  @override
  State<FinalizarLibroDialog> createState() => _FinalizarLibroDialogState();
}

class _FinalizarLibroDialogState extends State<FinalizarLibroDialog> {
  double? valoracion;

  final TextEditingController controller = TextEditingController();

  bool get esDecepcion => valoracion == 0;

  String get valoracionTexto {
    final valor = valoracion;

    if (valor == null) {
      return 'Selecciona una valoración';
    }

    if (valor == 0) {
      return 'No era para mí';
    }

    final texto = valor % 1 == 0
        ? valor.toInt().toString()
        : valor.toStringAsFixed(1).replaceAll('.', ',');

    return '$texto de 5';
  }

  void _seleccionarValoracion(double nuevaValoracion) {
    setState(() {
      valoracion = nuevaValoracion;
    });
  }

  void _finalizar() {
    final valor = valoracion;

    if (valor == null) return;

    Navigator.pop<Map<String, String>>(context, {
      // El backend admite 3, 3.5, 4.5, etc.
      'valoracion': valor.toString(),
      'reflexion': controller.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('⭐ Finalizar lectura'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Qué valoración le das al libro?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Puedes seleccionar estrellas completas o medias estrellas.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 18),

              Center(
                child: ClubRatingSelector(
                  valoracion: valoracion ?? 0,
                  enabled: !esDecepcion,
                  onChanged: _seleccionarValoracion,
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    valoracionTexto,
                    key: ValueKey(valoracionTexto),
                    style: TextStyle(
                      color: valoracion == null
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: ChoiceChip(
                  avatar: const Text('😞', style: TextStyle(fontSize: 18)),
                  label: const Text('No era para mí'),
                  selected: esDecepcion,
                  onSelected: (seleccionado) {
                    setState(() {
                      valoracion = seleccionado ? 0 : null;
                    });
                  },
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                '💭 Tu reseña (opcional)',
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
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: valoracion == null ? null : _finalizar,
          icon: const Icon(Icons.check),
          label: const Text('Finalizar'),
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
