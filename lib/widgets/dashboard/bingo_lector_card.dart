import 'package:flutter/material.dart';

import '../../models/bingo_lector.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_shimmer.dart';

/// Bingo lector: 25 retos de book journal (portada de un color, terminar
/// una saga, autor debut...) que la propia lectora marca a mano cuando un
/// libro los cumple — a propósito distinto de los logros, que se calculan
/// solos. Es autónomo: carga y guarda sus propias marcas.
class BingoLectorSection extends StatefulWidget {
  const BingoLectorSection({super.key});

  @override
  State<BingoLectorSection> createState() => _BingoLectorSectionState();
}

class _BingoLectorSectionState extends State<BingoLectorSection> {
  late Future<BingoLector> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<BingoLector> _cargar() async {
    final data = await ApiService().getBingoLector();
    return BingoLector.fromJson(data);
  }

  /// Cuenta filas, columnas y diagonales completas del cartón 5x5 — debe
  /// coincidir con `contarLineasBingo` en el backend (bingo.service.ts).
  int _lineasCompletadas(Set<String> marcadas) {
    bool marcada(int i) => marcadas.contains(kBingoCasillas[i].key);
    var lineas = 0;
    for (var r = 0; r < 5; r++) {
      if (List.generate(5, (c) => marcada(r * 5 + c)).every((v) => v)) lineas++;
    }
    for (var c = 0; c < 5; c++) {
      if (List.generate(5, (r) => marcada(r * 5 + c)).every((v) => v)) lineas++;
    }
    if (List.generate(5, (i) => marcada(i * 5 + i)).every((v) => v)) lineas++;
    if (List.generate(5, (i) => marcada(i * 5 + (4 - i))).every((v) => v)) lineas++;
    return lineas;
  }

  void _celebrar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, textAlign: TextAlign.center),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _tocarCasilla(BingoCasilla casilla, BingoLector actual) async {
    final marcada = actual.marcadas[casilla.key];
    final resultado = await showModalBottomSheet<_BingoDialogResultado>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BingoCasillaSheet(casilla: casilla, marcaActual: marcada),
    );
    if (resultado == null) return;

    final nuevasMarcadas = {...actual.marcadas}
      ..removeWhere((k, _) => k == casilla.key)
      ..addEntries(
        resultado.marcar
            ? [
                MapEntry(
                  casilla.key,
                  BingoMarca(squareKey: casilla.key, nota: resultado.nota),
                ),
              ]
            : const [],
      );

    // Aviso festivo al completar una línea o el cartón entero — solo al
    // marcar, nunca al desmarcar por error.
    if (resultado.marcar) {
      final total = kBingoCasillas.length;
      if (nuevasMarcadas.length == total && actual.marcadas.length < total) {
        _celebrar('🏆 ¡BINGO! Has completado el cartón entero');
      } else if (_lineasCompletadas(nuevasMarcadas.keys.toSet()) >
          _lineasCompletadas(actual.marcadas.keys.toSet())) {
        _celebrar('🎯 ¡Línea completa en el bingo lector!');
      }
    }

    // Optimista: se ve al instante, y si falla se recarga desde el server.
    setState(() {
      _future = Future.value(
        BingoLector(ok: actual.ok, year: actual.year, marcadas: nuevasMarcadas),
      );
    });
    try {
      await ApiService().marcarCasillaBingo(
        squareKey: casilla.key,
        marcar: resultado.marcar,
        nota: resultado.nota,
      );
    } catch (_) {
      if (mounted) setState(() => _future = _cargar());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BingoLector>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BingoSkeleton();
        }
        final bingo = snapshot.data;
        if (bingo == null || !bingo.ok) return const SizedBox.shrink();

        final marcadas = bingo.marcadas.length;
        final total = kBingoCasillas.length;
        final pct = total > 0 ? marcadas / total : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bingo lector ${bingo.year}',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$marcadas de $total casillas · toca una para marcarla',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: AppColors.primaryLight,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: kBingoCasillas.length,
              itemBuilder: (context, i) {
                final casilla = kBingoCasillas[i];
                return _BingoCell(
                  casilla: casilla,
                  marca: bingo.marcadas[casilla.key],
                  onTap: () => _tocarCasilla(casilla, bingo),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _BingoSkeleton extends StatelessWidget {
  const _BingoSkeleton();

  static BorderRadius _r(double r) => BorderRadius.circular(r);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClubShimmer(width: 24, height: 24, borderRadius: _r(4)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClubShimmer(width: 140, height: 14, borderRadius: _r(4)),
                  const SizedBox(height: 4),
                  ClubShimmer(width: 180, height: 11, borderRadius: _r(4)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClubShimmer(width: double.infinity, height: 6, borderRadius: _r(3)),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: 25,
          itemBuilder: (_, i) => ClubShimmer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: _r(8),
          ),
        ),
      ],
    );
  }
}

class _BingoCell extends StatelessWidget {
  const _BingoCell({required this.casilla, required this.marca, required this.onTap});
  final BingoCasilla casilla;
  final BingoMarca? marca;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final marcada = marca != null;
    final color = AppColors.gold;
    return Tooltip(
      message: marcada
          ? '${casilla.etiqueta}${marca?.nota != null ? '\n${marca!.nota}' : ''}'
          : casilla.etiqueta,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: marcada ? color.withValues(alpha: .16) : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: marcada ? color.withValues(alpha: .55) : AppColors.border,
                  width: marcada ? 1.6 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Opacity(
                opacity: marcada ? 1 : .55,
                child: Text(casilla.icono, style: const TextStyle(fontSize: 17)),
              ),
            ),
            if (marcada)
              Positioned(
                right: -4,
                top: -4,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: .5), blurRadius: 3),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, size: 9, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BingoDialogResultado {
  const _BingoDialogResultado({required this.marcar, this.nota});
  final bool marcar;
  final String? nota;
}

class _BingoCasillaSheet extends StatefulWidget {
  const _BingoCasillaSheet({required this.casilla, required this.marcaActual});
  final BingoCasilla casilla;
  final BingoMarca? marcaActual;

  @override
  State<_BingoCasillaSheet> createState() => _BingoCasillaSheetState();
}

class _BingoCasillaSheetState extends State<_BingoCasillaSheet> {
  late final _notaCtrl = TextEditingController(text: widget.marcaActual?.nota ?? '');

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yaMarcada = widget.marcaActual != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.casilla.icono, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.casilla.etiqueta,
                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notaCtrl,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: '¿Qué libro la cumplió? (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (yaMarcada)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const _BingoDialogResultado(marcar: false),
                      ),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                      child: const Text('Desmarcar'),
                    ),
                  ),
                if (yaMarcada) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _BingoDialogResultado(
                        marcar: true,
                        nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
                      ),
                    ),
                    child: Text(yaMarcada ? 'Guardar' : 'Marcar casilla'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
