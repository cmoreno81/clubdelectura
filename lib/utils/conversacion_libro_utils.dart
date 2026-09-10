import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../pages/configurar_lectura_page.dart';
import '../pages/lectura_page.dart';
import '../services/api_service.dart';

/// `true` si ya existe una lectura/conversación configurada para [libro]
/// (sin importar cuántas lectoras la tengan activa).
Future<bool> existeConversacionParaLibro(String libro) async {
  final configuracion = await ApiService().getConfiguracionLectura(
    libro: libro,
  );
  return configuracion.capitulos > 0;
}

/// Lleva a configurar una lectura libre para [libro] y, si se crea, entra
/// directamente en la conversación recién abierta. Devuelve `true` si
/// llegó a crearse (para que quien llama pueda refrescar su propio estado).
Future<bool> abrirNuevaConversacion(
  BuildContext context, {
  required String libro,
  String coverUrl = '',
}) async {
  final creada = await Navigator.push<bool>(
    context,
    AppPageRoute(builder: (_) => ConfigurarLecturaPage(libro: libro)),
  );
  if (creada != true || !context.mounted) return false;
  await Navigator.push(
    context,
    AppPageRoute(
      builder: (_) => LecturaPage(libro: libro, coverUrl: coverUrl),
    ),
  );
  return true;
}
