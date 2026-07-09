import 'package:flutter/material.dart';

import 'pages/splash_page.dart';
import 'services/usuario_service.dart';

const borrarUsuarioAlArrancar = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (borrarUsuarioAlArrancar) {
    await UsuarioService().borrarUsuario();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashPage(),
    );
  }
}
