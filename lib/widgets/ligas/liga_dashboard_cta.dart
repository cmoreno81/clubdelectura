import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../common/club_card.dart';

/// Aviso de las Ligas de ClubReads, reutilizado en el Inicio del club y en
/// Mi espacio (cuentas personales). En el Inicio global no hace falta: ahí
/// ya está la pestaña "Ligas" del menú flotante.
class LigaDashboardCta extends StatelessWidget {
  const LigaDashboardCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFB07B2A), Color(0xFFD9A441)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(24),
            bottomLeft: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ligas de ClubReads',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Compite cada quincena por leer a diario y terminar libros',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: .85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: .9),
            ),
          ],
        ),
      ),
    );
  }
}
