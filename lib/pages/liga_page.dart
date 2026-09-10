import 'package:flutter/material.dart';

import '../models/liga.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/error_view.dart';

/// Ligas de ClubReads — ranking individual por temporadas quincenales.
class LigaPage extends StatefulWidget {
  const LigaPage({super.key});

  @override
  State<LigaPage> createState() => _LigaPageState();
}

class _LigaPageState extends State<LigaPage> {
  late Future<LigaEstado> _future;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaEstado> _cargar() async {
    final data = await ApiService().getLiga();
    return LigaEstado.fromJson(data);
  }

  void _recargar() {
    setState(() => _future = _cargar());
  }

  Future<void> _unirme() async {
    if (_procesando) return;
    setState(() => _procesando = true);
    try {
      await ApiService().unirseLiga();
      _recargar();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _salir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dejar de participar'),
        content: const Text(
          'Dejarás de puntuar y de aparecer en la tabla. Tu histórico se '
          'conserva por si vuelves más adelante.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Dejar de participar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ApiService().salirLiga();
      _recargar();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ligas de ClubReads'),
        actions: [
          FutureBuilder<LigaEstado>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.data?.participando != true) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'salir') _salir();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'salir',
                    child: Text('Dejar de participar'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<LigaEstado>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }
          final estado = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: estado.participando
                ? _VistaParticipando(estado: estado)
                : _VistaInvitacion(
                    estado: estado,
                    procesando: _procesando,
                    onUnirme: _unirme,
                  ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No participa todavía
// ─────────────────────────────────────────────────────────────────────────────

class _VistaInvitacion extends StatelessWidget {
  const _VistaInvitacion({
    required this.estado,
    required this.procesando,
    required this.onUnirme,
  });

  final LigaEstado estado;
  final bool procesando;
  final VoidCallback onUnirme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.lg),
        const Center(child: Text('🏆', style: TextStyle(fontSize: 56))),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Compite en las Ligas de ClubReads',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Cada quincena, una liga nueva. Ganas puntos por leer a diario, '
          'mantener la racha, terminar libros y completar sagas. Al acabar la '
          'temporada, los puntos se reinician y empieza otra carrera.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _ComoSePuntua(),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: procesando ? null : onUnirme,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          child: procesando
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Unirme a la liga'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Puedes salir cuando quieras desde el menú de esta pantalla.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ComoSePuntua extends StatelessWidget {
  const _ComoSePuntua();

  static const _filas = [
    ('Check-in diario', '10 pts'),
    ('Bonus por racha', 'hasta 15 pts/día'),
    ('Páginas leídas', '1 pt / 20 págs'),
    ('Terminar un libro', '40 pts'),
    ('Terminar una saga', '100 pts'),
    ('Reseña con texto', '15 pts'),
  ];

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
            'Cómo se puntúa',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (accion, puntos) in _filas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(accion, style: AppTextStyles.bodySecondary),
                  Text(
                    puntos,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Participa
// ─────────────────────────────────────────────────────────────────────────────

class _VistaParticipando extends StatelessWidget {
  const _VistaParticipando({required this.estado});

  final LigaEstado estado;

  String _cuentaAtras() {
    final restante = estado.temporada.terminaEn.difference(DateTime.now());
    if (restante.isNegative) return 'Cerrando temporada…';
    final dias = restante.inDays;
    final horas = restante.inHours % 24;
    final minutos = restante.inMinutes % 60;
    if (dias > 0) return 'Termina en $dias ${dias == 1 ? 'día' : 'días'} $horas h';
    if (horas > 0) return 'Termina en $horas h $minutos min';
    return 'Termina en $minutos min';
  }

  @override
  Widget build(BuildContext context) {
    final t = estado.temporada;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Cabecera de temporada
        Container(
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
              Text(
                'Temporada ${t.numero + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _cuentaAtras(),
                style: TextStyle(color: Colors.white.withValues(alpha: .85)),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _PillCabecera(
                    valor: estado.miPuesto > 0 ? '#${estado.miPuesto}' : '—',
                    etiqueta: 'Tu puesto',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _PillCabecera(
                    valor: '${estado.misPuntos}',
                    etiqueta: 'Tus puntos',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _PillCabecera(
                    valor: '${t.totalParticipantes}',
                    etiqueta: 'Participantes',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (estado.historico.temporadasJugadas > 0) ...[
          _Historico(historico: estado.historico),
          const SizedBox(height: AppSpacing.lg),
        ],

        Text(
          'Clasificación',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (estado.tabla.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            alignment: Alignment.center,
            child: Text(
              'Aún no hay nadie en la tabla.\n¡Sé la primera en sumar puntos!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
          )
        else
          ..._filasConHuecos(estado.tabla),
      ],
    );
  }

  /// Inserta un separador "···" cuando hay un salto de puestos (top 10 + tu
  /// ventana no son contiguos).
  List<Widget> _filasConHuecos(List<LigaFila> filas) {
    final widgets = <Widget>[];
    for (var i = 0; i < filas.length; i++) {
      if (i > 0 && filas[i].puesto - filas[i - 1].puesto > 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Center(
              child: Text('···', style: TextStyle(color: AppColors.textMuted)),
            ),
          ),
        );
      }
      widgets.add(_FilaLiga(fila: filas[i]));
    }
    return widgets;
  }
}

class _PillCabecera extends StatelessWidget {
  const _PillCabecera({required this.valor, required this.etiqueta});
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

class _FilaLiga extends StatelessWidget {
  const _FilaLiga({required this.fila});
  final LigaFila fila;

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
            width: 34,
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

class _Historico extends StatelessWidget {
  const _Historico({required this.historico});
  final LigaHistorico historico;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Temporadas', '${historico.temporadasJugadas}'),
      ('Mejor puesto', historico.mejorPuesto != null ? '#${historico.mejorPuesto}' : '—'),
      ('Podios', '${historico.podios}'),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final (etiqueta, valor) in items)
            Expanded(
              child: Column(
                children: [
                  Text(
                    valor,
                    style: AppTextStyles.title.copyWith(fontSize: 18),
                  ),
                  Text(
                    etiqueta,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
