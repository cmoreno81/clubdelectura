import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import 'feedback_page.dart';
import 'politica_privacidad_page.dart';
import 'tecnologia_creditos_page.dart';

class AcercaDePage extends StatefulWidget {
  const AcercaDePage({super.key});

  @override
  State<AcercaDePage> createState() => _AcercaDePageState();
}

class _AcercaDePageState extends State<AcercaDePage> {
  late final Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de ClubReads')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          48,
        ),
        children: [
          ClubCard(
            elevated: false,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('ClubReads', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Nuestro rincón para compartir cada lectura.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FutureBuilder<PackageInfo>(
                    future: _packageInfo,
                    builder: (context, snapshot) {
                      final info = snapshot.data;
                      final version = info == null
                          ? 'Versión…'
                          : 'Versión ${info.version} (${info.buildNumber})';
                      return Text(version, style: AppTextStyles.caption);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClubCard(
            elevated: false,
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.code_rounded),
                    title: const Text('Tecnología y créditos'),
                    subtitle: const Text(
                      'Cómo está construida ClubReads y quién la hace posible',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push<void>(
                      context,
                      AppPageRoute(
                        builder: (_) => const TecnologiaCreditosPage(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Política de privacidad'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push<void>(
                      context,
                      AppPageRoute(
                        builder: (_) => const PoliticaPrivacidadPage(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Reportar error o sugerencia'),
                    subtitle: const Text(
                      'Cuéntanos qué falla o qué mejorarías',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push<void>(
                      context,
                      AppPageRoute(builder: (_) => const FeedbackPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
