import 'package:flutter/material.dart';

import '../../models/perfil_usuario.dart';
import '../../theme/app_spacing.dart';
import '../common/club_rating_selector.dart';

class EditarFechasLecturaDialog extends StatefulWidget {
  final PerfilLibroTerminado libro;

  const EditarFechasLecturaDialog({super.key, required this.libro});

  @override
  State<EditarFechasLecturaDialog> createState() =>
      _EditarFechasLecturaDialogState();
}

class _EditarFechasLecturaDialogState extends State<EditarFechasLecturaDialog> {
  DateTime? fechaInicio;
  DateTime? fechaFin;
  double? valoracion;
  late final TextEditingController resenaController;

  @override
  void initState() {
    super.initState();

    fechaInicio = _parseFecha(widget.libro.fechaInicio);
    fechaFin = _parseFecha(widget.libro.fechaFin);
    valoracion = _parseValoracion(widget.libro.valoracion);
    resenaController = TextEditingController(text: widget.libro.resena);

    if (fechaInicio != null &&
        fechaFin != null &&
        fechaFin!.isBefore(fechaInicio!)) {
      fechaFin = fechaInicio;
    }
  }

  @override
  void dispose() {
    resenaController.dispose();
    super.dispose();
  }

  DateTime? _parseFecha(String valor) {
    final partes = valor.trim().split('/');

    if (partes.length != 3) {
      return null;
    }

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final anio = int.tryParse(partes[2]);

    if (dia == null || mes == null || anio == null) {
      return null;
    }

    final fecha = DateTime(anio, mes, dia);

    if (fecha.year != anio || fecha.month != mes || fecha.day != dia) {
      return null;
    }

    return fecha;
  }

  String get valoracionTexto {
    final valor = valoracion;

    if (valor == null) {
      return 'Sin valoración';
    }

    if (valor == 0) {
      return 'No era para mí';
    }

    final texto = valor % 1 == 0
        ? valor.toInt().toString()
        : valor.toStringAsFixed(1).replaceAll('.', ',');

    return '$texto de 5';
  }

  double? _parseValoracion(String valor) {
    final texto = valor.trim().replaceAll('⭐️', '⭐').replaceAll(',', '.');

    if (texto.isEmpty) {
      return null;
    }

    if (texto == '😞') {
      return 0;
    }

    final numero = double.tryParse(texto);

    if (numero != null) {
      return numero.clamp(0, 5).toDouble();
    }

    final estrellas = RegExp('⭐').allMatches(texto).length;
    final tieneMedia = texto.contains('½');

    if (estrellas == 0 && !tieneMedia) {
      return null;
    }

    return (estrellas + (tieneMedia ? 0.5 : 0)).clamp(0, 5).toDouble();
  }

  String _formatoVisual(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  String _formatoApi(DateTime? fecha) {
    if (fecha == null) {
      return '';
    }

    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '${fecha.year}-$mes-$dia';
  }

  Future<void> _seleccionarInicio() async {
    final hoy = DateTime.now();

    final fechaInicial = fechaInicio ?? fechaFin ?? hoy;

    final ultimaFechaPermitida = fechaInicial.isAfter(hoy) ? fechaInicial : hoy;

    final elegida = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(1950),
      lastDate: ultimaFechaPermitida,
      helpText: 'Fecha de inicio',
    );

    if (elegida == null) return;
    if (!mounted) return;

    setState(() {
      fechaInicio = elegida;

      if (fechaFin != null && fechaFin!.isBefore(elegida)) {
        fechaFin = elegida;
      }
    });
  }

  Future<void> _seleccionarFin() async {
    final hoy = DateTime.now();

    final fechaInicial = fechaFin ?? fechaInicio ?? hoy;

    final ultimaFechaPermitida = fechaInicial.isAfter(hoy) ? fechaInicial : hoy;

    final primeraFechaPermitida = fechaInicio != null
        ? fechaInicio!
        : DateTime(1950);

    final elegida = await showDatePicker(
      context: context,
      initialDate: fechaInicial.isBefore(primeraFechaPermitida)
          ? primeraFechaPermitida
          : fechaInicial,
      firstDate: primeraFechaPermitida,
      lastDate: ultimaFechaPermitida,
      helpText: 'Fecha de fin',
    );

    if (elegida == null) return;
    if (!mounted) return;

    setState(() {
      fechaFin = elegida;
    });
  }

  void _guardar() {
    if (fechaInicio != null &&
        fechaFin != null &&
        fechaFin!.isBefore(fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de fin no puede ser anterior a la de inicio.',
          ),
        ),
      );

      return;
    }

    Navigator.pop<Map<String, String>>(context, {
      'fechaInicio': _formatoApi(fechaInicio),
      'fechaFin': _formatoApi(fechaFin),
      'valoracion': valoracion?.toString() ?? '',
      'resena': resenaController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.libro.libro,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('Fecha de inicio'),
                subtitle: Text(_formatoVisual(fechaInicio)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _seleccionarInicio,
              ),

              const SizedBox(height: AppSpacing.sm),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Fecha de fin'),
                subtitle: Text(_formatoVisual(fechaFin)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _seleccionarFin,
              ),
              const SizedBox(height: AppSpacing.md),

              const Text(
                'Valoración',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: AppSpacing.sm),

              Center(
                child: ClubRatingSelector(
                  valoracion: valoracion ?? 0,
                  onChanged: (nuevaValoracion) {
                    setState(() {
                      valoracion = nuevaValoracion;
                    });
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Center(
                child: Text(
                  valoracionTexto,
                  style: TextStyle(
                    color: valoracion == null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (valoracion != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        valoracion = null;
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Eliminar valoración'),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              TextField(
                controller: resenaController,
                minLines: 4,
                maxLines: 8,
                maxLength: 5000,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                scrollPadding: const EdgeInsets.only(bottom: 140),
                decoration: InputDecoration(
                  labelText: 'Sin reseña escrita.',
                  hintText: '¿Quieres añadir o modificar tu reseña?',
                  alignLabelWithHint: true,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _guardar,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
