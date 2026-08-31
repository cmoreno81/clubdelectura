import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';

import 'login_page.dart';
import 'registration_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.midnight, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .22),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 66,
                    color: Colors.white,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'CLUBREADS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Tu universo lector,\nsiempre contigo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Historias que se comparten',
              textAlign: TextAlign.center,
              style: AppTextStyles.section,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Guarda tus lecturas, descubre nuevos libros y vive cada club a tu manera.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        AppPageRoute(builder: (_) => const LoginPage()),
                      ),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Acceder'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        AppPageRoute(builder: (_) => const RegistrationPage()),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Crear una cuenta'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
