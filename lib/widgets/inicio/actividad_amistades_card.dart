import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../pages/perfil_amistad_page.dart';
import '../../services/amistades_cambios.dart';
import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../amistades/reacciones_progreso.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';

/// «Qué leen tus amistades» en Inicio: lo último que están leyendo o han
/// terminado, con la posibilidad de reaccionar. Si no hay nada, no sale.
class ActividadAmistadesCard extends StatefulWidget {
  const ActividadAmistadesCard({super.key, this.cargar});

  /// Para pruebas.
  final Future<List<ActividadAmistad>> Function()? cargar;

  @override
  State<ActividadAmistadesCard> createState() => _ActividadAmistadesCardState();
}

class _ActividadAmistadesCardState extends State<ActividadAmistadesCard>
    with AutomaticKeepAliveClientMixin {
  List<ActividadAmistad> _items = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    AmistadesCambios.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    AmistadesCambios.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final items =
          await (widget.cargar ?? ApiService().getActividadAmistades)();
      if (mounted) setState(() => _items = items.take(4).toList());
    } catch (_) {
      // Sin red o servidor antiguo: simplemente no sale.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: ClubCard(
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Qué leen tus amistades', style: AppTextStyles.section),
            const SizedBox(height: AppSpacing.sm),
            for (final item in _items) _fila(context, item),
          ],
        ),
      ),
    );
  }

  Widget _fila(BuildContext context, ActividadAmistad item) {
    final accion = item.esLectura
        ? 'está leyendo «${item.titulo}»${item.lectura == null ? '' : ' · ${item.lectura!.progreso}%'}'
        : 'ha terminado «${item.titulo}»'
              '${item.valoracion == null ? '' : ' · ⭐ ${item.valoracion!.toStringAsFixed(1)}'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => PerfilAmistadPage(nombre: item.nombre),
              ),
            ),
            child: Row(
              children: [
                ClubAvatar(
                  nombre: item.nombre,
                  imageUrl: item.avatarUrl,
                  size: 36,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: item.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: ' $accion'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.lectura != null)
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: ReaccionesProgreso(lectura: item.lectura!),
            ),
        ],
      ),
    );
  }
}
