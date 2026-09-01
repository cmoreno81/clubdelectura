import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/club_membership.dart';
import '../navigation/app_page_route.dart';
import '../services/api_exception.dart';
import '../services/club_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'clubs_page.dart';
import 'home_page.dart';

/// Pantalla de elección de modo al entrar en la app sin ningún club activo.
/// Ofrece tres caminos: espacio personal, crear club o unirse con código.
class ElegirModoPage extends StatefulWidget {
  const ElegirModoPage({super.key});

  @override
  State<ElegirModoPage> createState() => _ElegirModoPageState();
}

class _ElegirModoPageState extends State<ElegirModoPage>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _heroCtrl;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, .12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));
    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirEspacioPersonal() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final data = await ClubService().crearEspacioPersonal();
      if (!mounted) return;
      final clubData = data['club'] as Map<String, dynamic>? ?? {};
      final club = ClubMembership(
        id: clubData['id']?.toString() ?? '',
        nombre: clubData['nombre']?.toString() ?? 'Mi espacio lector',
        slug: '',
        rol: 'OWNER',
        activo: true,
        tipo: TipoClub.personal,
      );
      await Navigator.pushReplacement<void, void>(
        context,
        AppPageRoute(builder: (_) => HomePage(club: club)),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _irAClubs({bool joinMode = false}) async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push<ClubMembership?>(
      context,
      AppPageRoute(builder: (_) => const ClubsPage(onboarding: true)),
    );
    if (!mounted) return;
    // Si ClubsPage devolvió un club (creado o unido), navegar a HomePage
    if (result != null) {
      await Navigator.pushReplacement<void, void>(
        context,
        AppPageRoute(builder: (_) => HomePage(club: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botón volver
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.textSecondary,
                  tooltip: 'Volver',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeTransition(
                opacity: _heroFade,
                child: SlideTransition(position: _heroSlide, child: _Header()),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // Espacio personal — opción destacada
              _ModoCard(
                icon: '📖',
                title: 'Mi espacio lector',
                subtitle:
                    'Lee a tu ritmo. Sigue tus estadísticas, conquista logros y construye tu universo lector en solitario.',
                badgeLabel: 'NUEVO',
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                textColor: Colors.white,
                onTap: _busy ? null : _elegirEspacioPersonal,
                busy: _busy,
              ),
              const SizedBox(height: AppSpacing.md),
              // Crear club
              _ModoCard(
                icon: '👥',
                title: 'Crear un club',
                subtitle:
                    'Invita a amigos, elegid libros juntos y compartid vuestras lecturas.',
                onTap: _busy ? null : () => _irAClubs(),
              ),
              const SizedBox(height: AppSpacing.md),
              // Unirse con código
              _ModoCard(
                icon: '🔑',
                title: 'Tengo un código de invitación',
                subtitle: 'Alguien ya te ha invitado a su club lector.',
                onTap: _busy ? null : () => _irAClubs(joinMode: true),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.inkCoral],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Text('📚', style: TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Te damos la bienvenida a\nClubReads',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          '¿Cómo quieres usar la app?',
          style: TextStyle(fontSize: 17, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ModoCard extends StatelessWidget {
  const _ModoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient,
    this.textColor,
    this.badgeLabel,
    this.busy = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? textColor;
  final String? badgeLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = gradient != null;
    final fgColor = textColor ?? AppColors.textPrimary;
    final subtitleColor = textColor != null
        ? textColor!.withValues(alpha: .75)
        : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(20),
          border: gradient == null
              ? Border.all(color: AppColors.border, width: 1.5)
              : null,
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: .22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(icon, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: fgColor,
                              ),
                            ),
                          ),
                          if (badgeLabel != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeLabel!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.midnight,
                                  letterSpacing: .5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (busy)
                  SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: textColor ?? AppColors.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: subtitleColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
