import 'package:flutter/material.dart';

import '../models/liga.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';

/// Detalle de una temporada ya cerrada de las Ligas de ClubReads: su tabla
/// final completa, mi puesto/puntos y las medallas que gané esa temporada.
class LigaTemporadaPage extends StatefulWidget {
  const LigaTemporadaPage({super.key, required this.temporada});

  /// Nº de la temporada a mostrar (ver `numero`/`temporada` en el backend).
  final int temporada;

  @override
  State<LigaTemporadaPage> createState() => _LigaTemporadaPageState();
}

class _LigaTemporadaPageState extends State<LigaTemporadaPage> {
  late Future<LigaTemporadaCerrada> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaTemporadaCerrada> _cargar() async {
    final data = await ApiService().getLigaTemporadaCerrada(widget.temporada);
    return LigaTemporadaCerrada.fromJson(data);
  }

  void _recargar() {
    setState(() => _future = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Temporada ${widget.temporada + 1}')),
      body: FutureBuilder<LigaTemporadaCerrada>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (snapshot.hasError || data == null || !data.ok) {
            return _ErrorTemporada(
              mensaje: data?.mensaje,
              onRetry: _recargar,
            );
          }
          final t = data.temporada!;
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
                _CabeceraTemporada(temporada: t, data: data),
                if (data.medallas.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _MedallasTemporada(medallas: data.medallas),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Clasificación final',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.tabla.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    alignment: Alignment.center,
                    child: Text(
                      'No hay datos de la tabla para esta temporada.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                  )
                else
                  for (final fila in data.tabla)
                    _FilaTemporadaCerrada(fila: fila, division: t.division),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorTemporada extends StatelessWidget {
  const _ErrorTemporada({required this.mensaje, required this.onRetry});
  final String? mensaje;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              mensaje?.isNotEmpty == true
                  ? mensaje!
                  : 'No se ha podido cargar esta temporada.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CabeceraTemporada extends StatelessWidget {
  const _CabeceraTemporada({required this.temporada, required this.data});
  final LigaTemporadaCerradaInfo temporada;
  final LigaTemporadaCerrada data;

  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A4B12), Color(0xFFB07B2A), Color(0xFFD9A441)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Temporada ${temporada.numero + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      temporada.division.icono,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      temporada.division.etiqueta,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${_fecha(temporada.inicio)} – ${_fecha(temporada.fin)}',
            style: TextStyle(color: Colors.white.withValues(alpha: .85)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _PillTemporada(
                valor: data.miPuesto != null ? '#${data.miPuesto}' : '—',
                etiqueta: 'Tu puesto',
              ),
              const SizedBox(width: AppSpacing.sm),
              _PillTemporada(
                valor: '${data.misPuntos ?? 0}',
                etiqueta: 'Tus puntos',
              ),
              const SizedBox(width: AppSpacing.sm),
              _PillTemporada(
                valor: '${temporada.totalParticipantes}',
                etiqueta: 'Participantes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillTemporada extends StatelessWidget {
  const _PillTemporada({required this.valor, required this.etiqueta});
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              etiqueta,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedallasTemporada extends StatelessWidget {
  const _MedallasTemporada({required this.medallas});
  final List<LigaMedallaCerrada> medallas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medallas de esta temporada',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final m in medallas)
                Tooltip(
                  message: m.streak != null
                      ? '${m.tier.etiqueta} (racha de ${m.streak})'
                      : m.tier.etiqueta,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: m.tier.color.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: m.tier.color.withValues(alpha: .4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.tier.icono,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          m.tier.etiqueta,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaTemporadaCerrada extends StatelessWidget {
  const _FilaTemporadaCerrada({required this.fila, required this.division});
  final LigaFila fila;
  final LigaDivision division;

  String get _medalla => switch (fila.puesto) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
