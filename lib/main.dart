import 'package:club_lectura_app/services/atmosfera_scope.dart';
import 'package:flutter/material.dart';

import 'pages/splash_page.dart';
import 'services/atmosfera_controller.dart';
import 'services/usuario_service.dart';
import 'theme/app_theme.dart';
import 'theme/atmosferas/atmosfera_app_theme.dart';
import 'widgets/atmosferas/atmosfera_ambient_layer.dart';

const borrarUsuarioAlArrancar = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (borrarUsuarioAlArrancar) {
    await UsuarioService().borrarUsuario();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AtmosferaController atmosferaController;

  @override
  void initState() {
    super.initState();

    atmosferaController = AtmosferaController();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: atmosferaController,
      builder: (context, _) {
        final visual = atmosferaController.visual;

        final theme = AtmosferaAppTheme.aplicar(
          base: AppTheme.light,
          atmosfera: visual,
        );

        return AtmosferaScope(
          controller: atmosferaController,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ClubReads',
            theme: theme,

            themeAnimationDuration: const Duration(milliseconds: 700),
            themeAnimationCurve: Curves.easeInOutCubic,

            builder: (context, child) {
              final reducirMovimiento =
                  MediaQuery.maybeOf(context)?.disableAnimations ?? false;

              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: AtmosferaAmbientLayer(
                  atmosfera: atmosferaController.lectura,
                  color: visual.paleta.primary,
                  accentColor: visual.paleta.secondary,
                  backgroundColor: visual.paleta.background,
                  enabled:
                      atmosferaController.animacionesActivas &&
                      !reducirMovimiento,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },

            home: const SplashPage(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    atmosferaController.dispose();
    super.dispose();
  }
}
