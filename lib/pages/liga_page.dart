import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/liga.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../navigation/app_page_route.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/error_view.dart';
import 'liga_clubes_page.dart';
import 'liga_division_page.dart';
import 'liga_historial_page.dart';
import 'liga_temporada_page.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ligas de ClubReads'),
        actions: [
          IconButton(
            tooltip: 'Ligas entre clubes',
            icon: const Icon(Icons.groups_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LigaClubesPage()),
            ),
          ),
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
          'mantener la racha, terminar libros y completar sagas. Empiezas en '
          'Bronce y vas ascendiendo de división según tu puesto: 🥉 Bronce · '
          '🥈 Plata · 🥇 Oro · 💎 Platino · 👑 Diamante. Al acabar la temporada, '
          'los puntos se reinician y empieza otra carrera.',
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

const _kFilasPuntos = [
  (
    'Check-in diario',
    'Marca que has leído hoy desde el botón de check-in.',
    '10 pts',
  ),
  (
    'Bonus por racha',
    'Se suma sobre el check-in del día y crece con tu racha activa.',
    '+1 pt/día (tope 15)',
  ),
  (
    'Páginas leídas',
    'Según el tramo de páginas que registres ese día, igual que en tu '
        'mapa de calor.',
    '1 a 4 pts',
  ),
  (
    'Terminar un libro',
    'Cada libro que termines tras tenerlo en Leyendo ahora (las '
        'relecturas puntúan igual). Si lo marcas directamente como '
        'terminado, puntúa uno al día (menos si tiene menos de 100 '
        'páginas).',
    '40 pts',
  ),
  (
    'Terminar una saga',
    'Al completar una saga con un tomo que te dé puntos.',
    '100 pts',
  ),
  (
    'Reseña',
    'Si escribes una reseña de más de 200 caracteres en los 30 días '
        'siguientes a terminar un libro que te dé puntos.',
    '15 pts',
  ),
  (
    'Primer libro del mes',
    'El primer libro que termines dentro de cada mes natural.',
    '25 pts',
  ),
  (
    'Elegir Libro del año del mes',
    'Al seleccionar tu favorito del mes en Perfil → Favoritos, durante '
        'ese mes o el siguiente. Rellenar meses atrasados no puntúa.',
    '10 pts',
  ),
  (
    'Constancia entre temporadas',
    'Si en la temporada anterior sumaste puntos, esta empieza con un '
        'pequeño extra por seguir jugando.',
    '15 pts',
  ),
];

Widget _filasPuntosWidget() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final (accion, explicacion, puntos) in _kFilasPuntos)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accion,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    explicacion,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              puntos,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySecondary.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    const SizedBox(height: AppSpacing.sm),
    Text(
      'El bonus no es un check-in aparte: es un extra que se suma sobre '
      'los 10 pts del check-in de ese día, y crece con tu racha. Día 1 de '
      'racha: +1 (11 en total). Día 8: +8 (18 en total). Del día 15 en '
      'adelante siempre +15 (25 en total), sin volver a subir. La racha no '
      'se rompe si otro día solo actualizas el progreso de un libro sin '
      'hacer check-in — cuenta igual que en el mapa de calor.',
      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
    ),
  ],
);

class _ComoSePuntua extends StatelessWidget {
  const _ComoSePuntua();

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
          _filasPuntosWidget(),
        ],
      ),
    );
  }
}

/// Leyenda plegable única con las tres explicaciones de la liga (puntos,
/// divisiones y medallas) — antes eran tres desplegables separados y
/// empujaban la clasificación fuera de la pantalla; ahora comparten un
/// solo interruptor, con sub-apartados dentro.
class _LeyendaLigaPlegable extends StatefulWidget {
  const _LeyendaLigaPlegable({required this.actual});
  final LigaDivision actual;

  @override
  State<_LeyendaLigaPlegable> createState() => _LeyendaLigaPlegableState();
}

enum _LeyendaTab {
  puntos('Puntos', Icons.emoji_events_outlined),
  divisiones('Divisiones', Icons.stairs_outlined),
  medallas('Medallas', Icons.military_tech_outlined);

  const _LeyendaTab(this.etiqueta, this.icono);
  final String etiqueta;
  final IconData icono;
}

class _LeyendaLigaPlegableState extends State<_LeyendaLigaPlegable> {
  bool _abierta = false;
  _LeyendaTab _tab = _LeyendaTab.puntos;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => setState(() => _abierta = !_abierta),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Cómo funciona la liga',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _abierta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_abierta) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  for (final tab in _LeyendaTab.values) ...[
                    Expanded(
                      child: _ChipLeyendaTab(
                        tab: tab,
                        seleccionada: tab == _tab,
                        onTap: () => setState(() => _tab = tab),
                      ),
                    ),
                    if (tab != _LeyendaTab.values.last)
                      const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: switch (_tab) {
                _LeyendaTab.puntos => _filasPuntosWidget(),
                _LeyendaTab.divisiones => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final division in LigaDivision.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: division == widget.actual
                                    ? division.color.withValues(alpha: .18)
                                    : AppColors.surfaceSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                division.icono,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    division.etiqueta,
                                    style: AppTextStyles.bodySecondary.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: division == widget.actual
                                          ? division.color
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    division.descripcion,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (division == widget.actual)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.sm,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: division.color.withValues(
                                      alpha: .18,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  child: Text(
                                    'Tú',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: division.color,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Al cerrar la temporada, quien queda entre las primeras '
                      'de su división asciende, y quien queda entre las '
                      'últimas desciende (salvo en Bronce y Diamante, que son '
                      'el suelo y el techo).',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                _LeyendaTab.medallas => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final tier in LigaMedallaTier.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: tier.color.withValues(alpha: .18),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                tier.icono,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tier.etiqueta,
                                    style: AppTextStyles.bodySecondary.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    tier.descripcion,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Las medallas se van acumulando temporada tras '
                      'temporada — se puede ganar la misma varias veces '
                      '(salvo la de Diamante, que solo se gana una vez). '
                      'Se ven en tu perfil, y la más reciente junto a tu '
                      'nombre en la clasificación.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipLeyendaTab extends StatelessWidget {
  const _ChipLeyendaTab({
    required this.tab,
    required this.seleccionada,
    required this.onTap,
  });
  final _LeyendaTab tab;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: seleccionada
              ? AppColors.primary.withValues(alpha: .12)
              : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: seleccionada ? AppColors.primary : AppColors.border,
            width: seleccionada ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icono,
              size: 14,
              color: seleccionada ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              tab.etiqueta,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: seleccionada ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
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
    if (dias > 0) {
      return 'Termina en $dias ${dias == 1 ? 'día' : 'días'} $horas h';
    }
    if (horas > 0) return 'Termina en $horas h $minutos min';
    return 'Termina en $minutos min';
  }

  @override
  Widget build(BuildContext context) {
    final t = estado.temporada;
    return ListView(
      // En Android con navegación por gestos, la barra del sistema puede
      // tapar la última fila de la clasificación si solo dejamos el margen
      // estándar; sumamos el inset inferior real del dispositivo.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Temporada ${t.numero + 1}',
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
                          t.division.icono,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t.division.etiqueta,
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
                    etiqueta: 'En tu división',
                  ),
                ],
              ),
              if (estado.siguienteObjetivo != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'A ${estado.siguienteObjetivo!.diferencia} pts de '
                          '${estado.siguienteObjetivo!.nombre}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _EscaleraDivisiones(actual: t.division),
        const SizedBox(height: AppSpacing.lg),

        _LeyendaLigaPlegable(actual: t.division),
        const SizedBox(height: AppSpacing.lg),

        if (estado.historico.temporadasJugadas > 0) ...[
          _Historico(historico: estado.historico, divisionActual: t.division),
          const SizedBox(height: AppSpacing.sm),
          _AccesosHistorial(temporadaActual: t.numero),
          const SizedBox(height: AppSpacing.lg),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Clasificación',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            if (estado.tabla.isNotEmpty)
              Text(
                'Toca una fila para ver su desglose',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
          ],
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
      widgets.add(
        _FilaLiga(
          fila: filas[i],
          division: estado.temporada.division,
          totalParticipantes: estado.temporada.totalParticipantes,
        ),
      );
    }
    return widgets;
  }
}

/// Cuántas personas suben/bajan de división al cerrar la temporada — misma
/// fórmula que el backend (calcularCuotaAscensoDescenso en ligas.service.ts),
/// para poder marcar la zona de ascenso/descenso también en el cliente.
({int suben, int bajan}) _cuotaAscensoDescenso(int size) {
  if (size < 3) return (suben: 0, bajan: 0);
  final cuota = math.max(1, (size * 0.2).round());
  final tope = (size - 1) ~/ 2;
  final n = math.min(cuota, tope);
  return (suben: n, bajan: n);
}

/// Escalera de las 5 divisiones (como los grupos de una liga de fútbol),
/// siempre visible bajo la cabecera — deja claro de un vistazo que la tabla
/// de abajo es solo tu división, no un listado único de todo el mundo.
class _EscaleraDivisiones extends StatelessWidget {
  const _EscaleraDivisiones({required this.actual});
  final LigaDivision actual;

  @override
  Widget build(BuildContext context) {
    // Diamante arriba, Bronce abajo — igual que una escalera de ascensos.
    final divisiones = LigaDivision.values.reversed.toList();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final division in divisiones) ...[
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute(
                          builder: (_) => LigaDivisionPage(division: division),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: division == actual
                                    ? division.color.withValues(alpha: .18)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: division == actual
                                      ? division.color
                                      : AppColors.border,
                                  width: division == actual ? 1.6 : 1,
                                ),
                              ),
                              child: Text(
                                division.icono,
                                style: TextStyle(
                                  fontSize: division == actual ? 17 : 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              division.etiqueta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                fontWeight: division == actual
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: division == actual
                                    ? division.color
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (division != divisiones.last)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.textMuted.withValues(alpha: .5),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Toca una división para curiosear su clasificación',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
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
  const _FilaLiga({
    required this.fila,
    required this.division,
    required this.totalParticipantes,
  });
  final LigaFila fila;
  final LigaDivision division;
  final int totalParticipantes;

  String get _medalla => switch (fila.puesto) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };

  /// Color de la zona de ascenso/descenso de esta fila, como en una tabla de
  /// fútbol — null si está en la zona segura de en medio.
  Color? get _colorZona {
    final cuota = _cuotaAscensoDescenso(totalParticipantes);
    if (division != LigaDivision.diamante && fila.puesto <= cuota.suben) {
      return AppColors.success;
    }
    if (division != LigaDivision.bronce &&
        fila.puesto > totalParticipantes - cuota.bajan) {
      return AppColors.danger;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorZona = _colorZona;
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
            color: colorZona != null
                ? colorZona.withValues(alpha: .10)
                : fila.esTu
                ? AppColors.primary.withValues(alpha: .10)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: fila.esTu
                  ? AppColors.primary
                  : colorZona ?? AppColors.border,
              width: fila.esTu || colorZona != null ? 1.4 : 1,
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
              SizedBox(width: 22, child: _IndicadorTendencia(fila: fila)),
              ClubAvatar(
                nombre: fila.nombre,
                imageUrl: fila.avatarUrl,
                size: 34,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        fila.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: fila.esTu
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if ((fila.rachaHoy ?? 0) >= 7) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Racha activa de ${fila.rachaHoy} días',
                        child: const Text('🔥', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                    if (fila.medallaReciente != null) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message:
                            '${fila.medallaReciente!.tier.etiqueta} '
                            '(temporada ${fila.medallaReciente!.seasonNumber})',
                        child: Text(
                          fila.medallaReciente!.tier.icono,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ],
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
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flechita estilo parrilla de F1: sube/baja puestos desde el último ciclo
/// del cron (cada 1-3 h). Sin dato aún (recién unida) no muestra nada.
class _IndicadorTendencia extends StatelessWidget {
  const _IndicadorTendencia({required this.fila});
  final LigaFila fila;

  @override
  Widget build(BuildContext context) {
    final tendencia = fila.tendencia;
    if (tendencia == null || tendencia == LigaTendencia.igual) {
      return Icon(
        Icons.remove_rounded,
        size: 14,
        color: AppColors.textMuted.withValues(alpha: .5),
      );
    }
    final sube = tendencia == LigaTendencia.sube;
    final color = sube ? AppColors.success : AppColors.danger;
    final delta = (fila.delta ?? 0).abs();
    return Tooltip(
      message: sube ? 'Ha subido $delta puestos' : 'Ha bajado $delta puestos',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sube ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            size: 20,
            color: color,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desglose de puntos de una participante
// ─────────────────────────────────────────────────────────────────────────────

void abrirDesgloseLiga(BuildContext context, LigaFila fila) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _DesgloseSheet(fila: fila),
  );
}

class _DesgloseSheet extends StatefulWidget {
  const _DesgloseSheet({required this.fila});
  final LigaFila fila;

  @override
  State<_DesgloseSheet> createState() => _DesgloseSheetState();
}

class _DesgloseSheetState extends State<_DesgloseSheet> {
  late Future<LigaDesglose> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaDesglose> _cargar() async {
    final data = await ApiService().getLigaDesglose(widget.fila.userId);
    return LigaDesglose.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: FutureBuilder<LigaDesglose>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || snapshot.data?.ok != true) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    snapshot.data?.mensaje ??
                        'No se ha podido cargar el desglose.',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              );
            }
            final d = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    ClubAvatar(
                      nombre: d.nombre,
                      imageUrl: d.avatarUrl,
                      size: 44,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.nombre,
                            style: AppTextStyles.title.copyWith(fontSize: 17),
                          ),
                          Text(
                            d.puesto != null
                                ? '#${d.puesto} · ${d.puntos} pts · ${d.division.icono} ${d.division.etiqueta}'
                                : '${d.puntos} pts · ${d.division.icono} ${d.division.etiqueta}',
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (d.desglose.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Center(
                      child: Text(
                        'Aún no tiene puntos esta temporada.',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                  )
                else
                  for (final item in d.desglose)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.etiqueta,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${item.eventos} ${item.eventos == 1 ? 'vez' : 'veces'}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${item.puntos}',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Historico extends StatelessWidget {
  const _Historico({required this.historico, required this.divisionActual});
  final LigaHistorico historico;
  final LigaDivision divisionActual;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Temporadas', '${historico.temporadasJugadas}'),
      (
        'Mejor puesto',
        historico.mejorPuesto != null ? '#${historico.mejorPuesto}' : '—',
      ),
      ('Podios', '${historico.podios}'),
      (
        'División',
        '${divisionActual.icono} ${divisionActual.etiqueta}',
      ),
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

/// Accesos a la temporada cerrada más reciente y al histórico completo —
/// se muestran solo cuando ya hay al menos una temporada cerrada
/// ([estado.historico.temporadasJugadas] > 0, comprobado por quien llama).
class _AccesosHistorial extends StatelessWidget {
  const _AccesosHistorial({required this.temporadaActual});

  /// Nº de la temporada en curso — la anterior (ya cerrada) es esta menos 1.
  final int temporadaActual;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BotonHistorial(
            icon: Icons.emoji_events_outlined,
            label: 'Temporada anterior',
            onTap: () => Navigator.push(
              context,
              AppPageRoute(
                builder: (_) =>
                    LigaTemporadaPage(temporada: temporadaActual - 1),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _BotonHistorial(
            icon: Icons.history_rounded,
            label: 'Ver histórico',
            onTap: () => Navigator.push(
              context,
              AppPageRoute(builder: (_) => const LigaHistorialPage()),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonHistorial extends StatelessWidget {
  const _BotonHistorial({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(alignment: Alignment.center),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
