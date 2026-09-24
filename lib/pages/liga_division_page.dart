import 'package:flutter/material.dart';

import '../models/liga.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/error_view.dart';
import 'liga_page.dart' show abrirDesgloseLiga;

/// Tabla EN VIVO de una división cualquiera de las Ligas de ClubReads — no
/// solo la del usuario. Deja claro si es o no su propia división.
class LigaDivisionPage extends StatefulWidget {
  const LigaDivisionPage({super.key, required this.division});

  final LigaDivision division;

  @override
  State<LigaDivisionPage> createState() => _LigaDivisionPageState();
}

class _LigaDivisionPageState extends State<LigaDivisionPage> {
  late Future<LigaDivisionTabla> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaDivisionTabla> _cargar() async {
    final data = await ApiService().getLigaDivision(widget.division.valorApi);
    return LigaDivisionTabla.fromJson(data);
  }

  void _recargar() {
    setState(() => _future = _cargar());
  }

  String _cuentaAtras(DateTime? terminaEn) {
    if (terminaEn == null) return '';
    final restante = terminaEn.difference(DateTime.now());
    if (restante.isNegative) return 'Cerrando temporada…';
    final dias = restante.inDays;
    final horas = restante.inHours % 24;
    if (dias > 0) return 'Termina en $dias ${dias == 1 ? 'día' : 'días'} $horas h';
    return 'Termina en $horas h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.division.icono} ${widget.division.etiqueta}'),
      ),
      body: FutureBuilder<LigaDivisionTabla>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (snapshot.hasError || data == null || !data.ok) {
            return ErrorView(mensaje: data?.mensaje, onRetry: _recargar);
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                _CabeceraDivision(
                  division: data.division,
                  cuentaAtras: _cuentaAtras(data.terminaEn),
                  totalParticipantes: data.totalParticipantes,
                  esTuDivision: data.esTuDivision,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Clasificación en vivo',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (data.tabla.isNotEmpty)
                      Text(
                        'Toca una fila para ver su desglose',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.tabla.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    alignment: Alignment.center,
                    child: Text(
                      'Todavía no hay nadie en esta división.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                  )
                else
                  for (final fila in data.tabla)
                    _FilaDivision(fila: fila),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CabeceraDivision extends StatelessWidget {
  const _CabeceraDivision({
    required this.division,
    required this.cuentaAtras,
    required this.totalParticipantes,
    required this.esTuDivision,
  });

  final LigaDivision division;
  final String cuentaAtras;
  final int totalParticipantes;
  final bool esTuDivision;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: division.color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: division.color.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(division.icono, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  division.etiqueta,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w900,
                    color: division.color,
                  ),
                ),
              ),
              if (esTuDivision)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: division.color,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Text(
                    'Tu división',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            esTuDivision
                ? 'Aquí compites tú — $cuentaAtras'
                : 'No compites aquí, solo estás mirando — $cuentaAtras',
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalParticipantes participantes',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _FilaDivision extends StatelessWidget {
  const _FilaDivision({required this.fila});
  final LigaFila fila;

  String get _medalla => switch (fila.puesto) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => abrirDesgloseLiga(context, fila),
        child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fila.esTu
            ? AppColors.primary.withValues(alpha: .10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: fila.esTu ? AppColors.primary : AppColors.border,
          width: fila.esTu ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              _medalla.isNotEmpty ? _medalla : '${fila.puesto}',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ClubAvatar(nombre: fila.nombre, imageUrl: fila.avatarUrl, size: 34),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              fila.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontWeight: fila.esTu ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${fila.puntos}',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          Text(
            ' pts',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
