import 'package:flutter/material.dart';
import '../common/club_rating_selector.dart';

class FinalizarLibroDialog extends StatefulWidget {
  final DateTime? fechaInicioActual;
  final String formatoActual;

  const FinalizarLibroDialog({
    super.key,
    this.fechaInicioActual,
    this.formatoActual = '',
  });

  @override
  State<FinalizarLibroDialog> createState() => _FinalizarLibroDialogState();
}

class _FinalizarLibroDialogState extends State<FinalizarLibroDialog> {
  double? valoracion;
  late String formato;
  late DateTime fechaInicio;
  late DateTime fechaFin;

  final TextEditingController controller = TextEditingController();

  bool get esDecepcion => valoracion == 0;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    final actual = widget.fechaInicioActual;
    fechaInicio = actual == null || actual.isAfter(hoy) ? hoy : actual;
    fechaFin = hoy;
    formato = widget.formatoActual;
  }

  String get fechaInicioTexto {
    final dia = fechaInicio.day.toString().padLeft(2, '0');
    final mes = fechaInicio.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fechaInicio.year}';
  }

  String get fechaInicioApi {
    final dia = fechaInicio.day.toString().padLeft(2, '0');
    final mes = fechaInicio.month.toString().padLeft(2, '0');
    return '${fechaInicio.year}-$mes-$dia';
  }

  String _fechaTexto(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  String _fechaApi(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  Future<void> _seleccionarFechaInicio() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: fechaInicio,
      firstDate: DateTime(1950),
      lastDate: hoy,
      helpText: 'Fecha de inicio de la lectura',
    );
    if (elegida != null && mounted) {
      setState(() {
        fechaInicio = elegida;
        if (fechaFin.isBefore(fechaInicio)) fechaFin = fechaInicio;
      });
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: fechaFin.isBefore(fechaInicio) ? fechaInicio : fechaFin,
      firstDate: fechaInicio,
      lastDate: hoy,
      helpText: 'Fecha de finalización de la lectura',
    );
    if (elegida != null && mounted) setState(() => fechaFin = elegida);
  }

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

    if (valor == null || formato.isEmpty) return;

    Navigator.pop<Map<String, String>>(context, {
      // El backend admite 3, 3.5, 4.5, etc.
      'valoracion': valor.toString(),
      'reflexion': controller.text.trim(),
      'fechaInicio': fechaInicioApi,
      'fechaFin': _fechaApi(fechaFin),
      'formato': formato,
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_calendar_outlined),
                title: const Text('Fecha de inicio'),
                subtitle: Text(fechaInicioTexto),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _seleccionarFechaInicio,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Fecha de finalización'),
                subtitle: Text(_fechaTexto(fechaFin)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _seleccionarFechaFin,
              ),

              const SizedBox(height: 24),

              const Text(
                '¿En qué formato lo has leído?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final opcion in const [
                    ('FISICO', '📖 Físico'),
                    ('DIGITAL', '📱 Digital'),
                    ('AUDIOLIBRO', '🎧 Audiolibro'),
                  ])
                    ChoiceChip(
                      label: Text(
                        opcion.$2,
                        style: TextStyle(
                          color: formato == opcion.$1
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: formato == opcion.$1
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      selected: formato == opcion.$1,
                      selectedColor: colorScheme.primary,
                      checkmarkColor: colorScheme.onPrimary,
                      onSelected: (_) => setState(() => formato = opcion.$1),
                    ),
                ],
              ),

              const SizedBox(height: 24),

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
                  selectedColor: colorScheme.primary,
                  checkmarkColor: colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    color: esDecepcion
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: esDecepcion ? FontWeight.w800 : FontWeight.w500,
                  ),
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
          onPressed: valoracion == null || formato.isEmpty ? null : _finalizar,
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
