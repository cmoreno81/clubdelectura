import 'package:club_lectura_app/services/atmosfera_scope.dart';
import 'package:flutter/material.dart';

import 'pages/splash_page.dart';
import 'pages/club_gate_page.dart';
import 'pages/login_page.dart';
import 'pages/welcome_page.dart';
import 'services/auth_session_service.dart';
import 'services/auth_service.dart';
import 'services/atmosfera_controller.dart';
import 'theme/app_theme.dart';
import 'theme/atmosferas/atmosfera_app_theme.dart';
import 'widgets/atmosferas/atmosfera_ambient_layer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AtmosferaController atmosferaController;
  final authSession = AuthSessionService.instance;
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    atmosferaController = AtmosferaController();
    authSession.addListener(_onAuthChanged);
    authSession.bootstrap(refreshSession: AuthService().refreshExistingSession);
  }

  void _onAuthChanged() {
    if (!authSession.initialized || authSession.isAuthenticated) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
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
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'ClubReads',
            theme: theme,

            themeAnimationDuration: Duration.zero,

            builder: (context, child) {
              final reducirMovimiento =
                  MediaQuery.maybeOf(context)?.disableAnimations ?? false;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
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

            home: AnimatedBuilder(
              animation: authSession,
              builder: (context, _) {
                if (!authSession.initialized) return const SplashPage();
                return authSession.isAuthenticated
                    ? const ClubGatePage()
                    : authSession.sessionExpired
                    ? const LoginPage()
                    : const WelcomePage();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    authSession.removeListener(_onAuthChanged);
    atmosferaController.dispose();
    super.dispose();
  }
}
