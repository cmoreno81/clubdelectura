import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../pages/amistades_page.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_card.dart';

/// Atajo de Inicio a Amistades. Si el servidor no responde (o aún no
/// conoce las amistades) no se muestra nada.
class AmistadesAtajoCard extends StatefulWidget {
  const AmistadesAtajoCard({super.key, this.cargar, this.abrir});

  /// Para pruebas.
  final Future<AmistadesData> Function()? cargar;
  final Future<void> Function(BuildContext context)? abrir;

  @override
  State<AmistadesAtajoCard> createState() => _AmistadesAtajoCardState();
}

class _AmistadesAtajoCardState extends State<AmistadesAtajoCard>
    with AutomaticKeepAliveClientMixin {
  AmistadesData? _data;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await (widget.cargar ?? ApiService().getAmistades)();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      // Sin red o servidor antiguo: el atajo no sale.
    }
  }

  Future<void> _abrir() async {
    if (widget.abrir != null) {
      await widget.abrir!(context);
    } else {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const AmistadesPage()),
      );
    }
    if (mounted) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final pendientes = data.recibidas.length;
    final subtitulo = pendientes > 0
        ? (pendientes == 1
              ? '1 solicitud por responder'
              : '$pendientes solicitudes por responder')
        : data.amistades.isEmpty
        ? 'Añade a gente con su nombre o con un código'
        : '${data.amistades.length} ${data.amistades.length == 1 ? 'amistad' : 'amistades'}';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: ClubCard(
        elevated: false,
        onTap: _abrir,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const Text('👥', style: TextStyle(fontSize: 26)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amistades', style: AppTextStyles.section),
                  Text(
                    subtitulo,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: pendientes > 0 ? AppColors.primary : null,
                      fontWeight: pendientes > 0 ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            if (pendientes > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pendientes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
