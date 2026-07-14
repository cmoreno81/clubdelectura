import 'package:flutter/material.dart';

import '../../models/perfil_usuario.dart';
import '../../theme/app_spacing.dart';

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

  @override
  void initState() {
    super.initState();

    fechaInicio = _parseFecha(widget.libro.fechaInicio);
    fechaFin = _parseFecha(widget.libro.fechaFin);

    if (fechaInicio != null &&
        fechaFin != null &&
        fechaFin!.isBefore(fechaInicio!)) {
      fechaFin = fechaInicio;
    }
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

    return DateTime(anio, mes, dia);
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
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
