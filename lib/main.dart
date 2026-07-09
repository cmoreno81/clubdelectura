import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:flutter/material.dart';

import 'pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await UsuarioService().borrarUsuario(); // <-- borrar solo para probar

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SplashPage()),
  );
}
