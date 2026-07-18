import 'package:flutter/material.dart';

class PausarLecturaDialog extends StatefulWidget {
  const PausarLecturaDialog({super.key});

  @override
  State<PausarLecturaDialog> createState() => _PausarLecturaDialogState();
}

class _PausarLecturaDialogState extends State<PausarLecturaDialog> {
  final TextEditingController _otroMotivoController = TextEditingController();

  String? _motivoSeleccionado;

  static const List<_MotivoPausa> _motivos = [
    _MotivoPausa(
      valor: 'Necesito descansar un poco',
      icono: '😴',
      titulo: 'Necesito descansar un poco',
    ),
    _MotivoPausa(
      valor: 'Estoy leyendo otro libro',
      icono: '📚',
      titulo: 'Estoy leyendo otro libro',
    ),
    _MotivoPausa(
      valor: 'Ahora no es el momento',
      icono: '⏳',
      titulo: 'Ahora no es el momento',
    ),
    _MotivoPausa(
      valor: 'Estoy esperando para continuar',
      icono: '📖',
      titulo: 'Estoy esperando para continuar',
    ),
    _MotivoPausa(valor: 'OTRO', icono: '💭', titulo: 'Otro motivo'),
  ];

  bool get _esOtro => _motivoSeleccionado == 'OTRO';

  String get _motivoFinal {
    if (_motivoSeleccionado == null) {
      return '';
    }

    if (_esOtro) {
      return _otroMotivoController.text.trim();
    }

    return _motivoSeleccionado!;
  }

  void _confirmar() {
    Navigator.pop<String>(context, _motivoFinal);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.pause_circle_outline_rounded),
          SizedBox(width: 10),
          Expanded(child: Text('Pausar lectura')),
        ],
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Qué ha pasado?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 4),

              Text(
                'El motivo es opcional y podrás retomar '
                'la lectura cuando quieras.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 16),

              RadioGroup<String>(
                groupValue: _motivoSeleccionado,
                onChanged: (value) {
                  setState(() {
                    _motivoSeleccionado = value;
                  });
                },
                child: Column(
                  children: _motivos.map((motivo) {
                    final seleccionada = _motivoSeleccionado == motivo.valor;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<String>(
                        value: motivo.valor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: seleccionada
                            ? Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.45)
                            : null,
                        title: Text('${motivo.icono}  ${motivo.titulo}'),
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (_esOtro) ...[
                const SizedBox(height: 8),

                TextField(
                  controller: _otroMotivoController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 240,
                  decoration: const InputDecoration(
                    labelText: 'Cuéntanoslo',
                    hintText: 'Escribe el motivo, si te apetece...',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
              ],
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

        TextButton(
          onPressed: () {
            Navigator.pop<String>(context, '');
          },
          child: const Text('Pausar sin motivo'),
        ),

        FilledButton.icon(
          onPressed: _motivoSeleccionado == null ? null : _confirmar,
          icon: const Icon(Icons.pause_rounded),
          label: const Text('Pausar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _otroMotivoController.dispose();
    super.dispose();
  }
}

class _MotivoPausa {
  final String valor;
  final String icono;
  final String titulo;

  const _MotivoPausa({
    required this.valor,
    required this.icono,
    required this.titulo,
  });
}
