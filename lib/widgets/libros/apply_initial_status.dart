import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'finalizar_libro_dialog.dart';

/// Tras añadir un libro con éxito (queda como PENDIENTE en el servidor),
/// aplica el estado inicial elegido en el selector de [AddBookSheet] cuando
/// no era "Quiero leerlo". Devuelve el estado realmente alcanzado:
/// 'PENDIENTE' si no se pidió otra cosa, si la actualización de estado
/// falló, o si se canceló el diálogo de valoración al elegir "Ya lo he
/// leído" — en cualquiera de esos casos el libro ya quedó añadido como
/// pendiente por la llamada anterior, así que nunca se trata como un fallo
/// de la operación completa.
Future<String> aplicarEstadoInicial(
  BuildContext context, {
  required String usuario,
  required String libro,
  required String estadoElegido,
  required String formato,
}) async {
  if (estadoElegido == 'LEYENDO') {
    final ok = await ApiService().actualizarEstado(
      usuario: usuario,
      libro: libro,
      estado: 'LEYENDO',
      formato: formato,
    );
    return ok ? 'LEYENDO' : 'PENDIENTE';
  }

  if (estadoElegido == 'FINALIZADO') {
    if (!context.mounted) return 'PENDIENTE';
    final resultado = await FinalizarLibroDialog.show(
      context,
      formatoActual: formato,
    );
    if (resultado == null || !context.mounted) return 'PENDIENTE';
    final ok = await ApiService().actualizarEstado(
      usuario: usuario,
      libro: libro,
      estado: 'FINALIZADO',
      valoracion: resultado['valoracion'],
      reflexion: resultado['reflexion'],
      fechaInicio: resultado['fechaInicio'],
      fechaFin: resultado['fechaFin'],
      formato: resultado['formato'],
    );
    return ok ? 'FINALIZADO' : 'PENDIENTE';
  }

  return 'PENDIENTE';
}
