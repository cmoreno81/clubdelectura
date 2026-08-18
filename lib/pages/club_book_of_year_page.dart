import 'package:flutter/material.dart';

import '../models/club_book_of_year.dart';
import '../models/clubvision_estadisticas.dart';
import '../navigation/app_page_route.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_shimmer.dart';
import '../widgets/common/optimized_network_image.dart';
import 'clubvision_estadisticas_page.dart';

class ClubBookOfYearPage extends StatefulWidget {
  const ClubBookOfYearPage({super.key, this.initialYear});
  final int? initialYear;
  @override
  State<ClubBookOfYearPage> createState() => _ClubBookOfYearPageState();
}

class _ClubBookOfYearPageState extends State<ClubBookOfYearPage> {
  late int _year = widget.initialYear ?? DateTime.now().year;
  late Future<ClubBookOfYearEdition?> _future = ApiService()
      .getClubBookOfYearEdition(_year);
  bool _saving = false;

  void _reload([ClubBookOfYearEdition? edition]) => setState(() {
    _future = edition == null
        ? ApiService().getClubBookOfYearEdition(_year)
        : Future.value(edition);
  });

  Future<void> _mutate(String action, Map<String, dynamic> body) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final edition = await ApiService().mutateClubBookOfYear(action, {
        'anio': _year,
        ...body,
      });
      if (mounted) _reload(edition);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirm(String message, VoidCallback action) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar acción'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (accepted == true) action();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Libro del año del club'),
      actions: [
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _year,
            items: List.generate(5, (i) => DateTime.now().year - i)
                .map(
                  (year) => DropdownMenuItem(value: year, child: Text('$year')),
                )
                .toList(),
            onChanged: (year) {
              if (year == null) return;
              setState(() {
                _year = year;
                _future = ApiService().getClubBookOfYearEdition(year);
              });
            },
          ),
        ),
      ],
    ),
    body: FutureBuilder<ClubBookOfYearEdition?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CardListSkeleton(count: 4);
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo cargar la edición'),
                TextButton(onPressed: _reload, child: const Text('Reintentar')),
              ],
            ),
          );
        }
        final edition = snapshot.data;
        if (edition == null || edition.status == 'NOT_STARTED') {
          return _NotStarted(
            year: _year,
            saving: _saving,
            canAdmin: edition?.canAdmin ?? false,
            onStart: () => _confirm(
              'Se creará una edición en preparación. Las nuevas lecturas oficiales podrán añadirse hasta abrir la votación.',
              () => _mutate('iniciarLibroDelAnioClub', const {}),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _EditionHeader(edition: edition),
            if (edition.status == 'PREPARING')
              _PreparingEdition(
                edition: edition,
                saving: _saving,
                onSync: () =>
                    _mutate('sincronizarCandidatasLibroDelAnioClub', const {}),
                onReview: _reviewPreparingCandidates,
                onOpen: () => _confirmOpenVoting(edition),
              ),
            if (edition.canAdmin && edition.status != 'FINISHED')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _confirm(
                          'Solo se puede cancelar una edición que todavía no tenga votos.',
                          () => _mutate('cancelarLibroDelAnioClub', const {}),
                        ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar edición'),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (edition.status == 'QUALIFYING' || edition.status == 'TIEBREAK')
              _Qualifying(
                edition: edition,
                saving: _saving,
                onVote: (ids) => _mutate('votarClasificacionLibroDelAnioClub', {
                  'candidateIds': ids,
                }),
                onClose: edition.canAdmin
                    ? () => _confirm(
                        'Se cerrará la clasificación y se preparará el cuadro. Esta acción no muestra resultados anticipados.',
                        () => _mutate(
                          'cerrarClasificacionLibroDelAnioClub',
                          const {},
                        ),
                      )
                    : null,
              ),
            for (final round in edition.rounds.where(
              (round) => round.phase != 'QUALIFYING',
            )) ...[
              _RoundCard(
                round: round,
                saving: _saving,
                canAdmin: edition.canAdmin,
                onOpen: () => _mutate('abrirRondaLibroDelAnioClub', {
                  'roundId': round.id,
                }),
                onClose: () => _confirm(
                  'Se contarán los votos y se cerrará la ronda. Los empates no se resolverán automáticamente.',
                  () => _mutate('cerrarRondaLibroDelAnioClub', {
                    'roundId': round.id,
                  }),
                ),
                onVote: (duelId, candidateId) => _mutate(
                  'votarDueloLibroDelAnioClub',
                  {'duelId': duelId, 'candidateId': candidateId},
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    ),
  );

  Future<void> _confirmOpenVoting(ClubBookOfYearEdition edition) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar candidaturas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${edition.candidates.length} candidatas detectadas'),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Al abrir la votación se cerrará la lista de candidatas. Las nuevas lecturas oficiales que se registren después no entrarán en esta edición.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir preparando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar candidaturas y abrir votación'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await _mutate('abrirVotacionLibroDelAnioClub', const {});
    }
  }

  Future<void> _reviewPreparingCandidates() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final preview = await ApiService().prepareClubBookOfYear(_year);
      if (!mounted) return;
      final unresolved = (preview['unresolvedCandidates'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      final books = (preview['linkableBooks'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Revisar candidatas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (unresolved.isEmpty)
                const ListTile(
                  leading: Icon(Icons.check_circle_outline_rounded),
                  title: Text('No hay lecturas históricas pendientes'),
                ),
              for (final item in unresolved)
                ListTile(
                  leading: const Icon(Icons.link_off_rounded),
                  title: Text(item['title']?.toString() ?? ''),
                  subtitle: Text('Clubvisión · ${item['edition']}'),
                  trailing: PopupMenuButton<Map>(
                    tooltip: 'Vincular con un libro',
                    itemBuilder: (_) => books
                        .map(
                          (book) => PopupMenuItem<Map>(
                            value: book,
                            child: Text(book['title']?.toString() ?? ''),
                          ),
                        )
                        .toList(),
                    onSelected: (book) async {
                      await ApiService().linkClubBookOfYearHistoricalCandidate(
                        year: _year,
                        resultId: item['resultId']?.toString() ?? '',
                        bookId: book['bookId']?.toString() ?? '',
                      );
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ),
            ],
          ),
        ),
      );
      if (mounted) {
        final edition = await ApiService().mutateClubBookOfYear(
          'sincronizarCandidatasLibroDelAnioClub',
          {'anio': _year},
        );
        if (mounted) _reload(edition);
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PreparingEdition extends StatefulWidget {
  const _PreparingEdition({
    required this.edition,
    required this.saving,
    required this.onSync,
    required this.onReview,
    required this.onOpen,
  });
  final ClubBookOfYearEdition edition;
  final bool saving;
  final VoidCallback onSync;
  final VoidCallback onReview;
  final VoidCallback onOpen;

  @override
  State<_PreparingEdition> createState() => _PreparingEditionState();
}

class _PreparingEditionState extends State<_PreparingEdition> {
  late final Future<ClubvisionEstadisticas?> _statsFuture =
      ApiService().getClubvisionEstadisticas().then<ClubvisionEstadisticas?>(
        (s) => s,
        onError: (_) => null,
      );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: ClubCard(
      child: FutureBuilder<ClubvisionEstadisticas?>(
        future: _statsFuture,
        builder: (context, snap) {
          final stats = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edición en preparación',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Las nuevas lecturas oficiales se añadirán hasta que abras la votación.',
              ),
              if (widget.edition.candidatesSyncedAt != null)
                Text(
                  'Última actualización: ${widget.edition.candidatesSyncedAt!.toLocal().day}/${widget.edition.candidatesSyncedAt!.toLocal().month}/${widget.edition.candidatesSyncedAt!.toLocal().year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: AppSpacing.md),
              for (final candidate in widget.edition.candidates) ...[
                _CandidateRow(
                  candidate: candidate,
                  ganador: stats?.ganadores
                      .where((g) => g.bookId == candidate.bookId)
                      .firstOrNull,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              // ── Enlace a estadísticas ─────────────────────────────────
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (_) => const ClubvisionEstadisticasPage(),
                      ),
                    ),
                    icon: const Icon(Icons.bar_chart_rounded, size: 18),
                    label: const Text('Ver estadísticas completas'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              if (widget.edition.canAdmin) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.saving ? null : widget.onSync,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Actualizar candidatas'),
                    ),
                    TextButton.icon(
                      onPressed: widget.saving ? null : widget.onReview,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Revisar candidatas'),
                    ),
                    FilledButton(
                      onPressed:
                          widget.saving || widget.edition.candidates.length < 2
                          ? null
                          : widget.onOpen,
                      child: const Text('Abrir votación'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

// ── Fila individual de candidata con mini-stats ───────────────────────────────

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate, this.ganador});
  final ClubBookOfYearCandidate candidate;
  final ClubvisionGanadorStats? ganador;

  @override
  Widget build(BuildContext context) {
    final label = candidate.needsReview
        ? 'Revisión pendiente'
        : candidate.source == 'CLUBVISION'
        ? 'Clubvisión · ${candidate.clubvisionEdition ?? ''}'
        : 'Lectura oficial';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Cover(candidate: candidate),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        candidate.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (candidate.needsReview)
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                  ],
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (ganador != null) ...[
                  const SizedBox(height: 5),
                  _MiniStats(ganador: ganador!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStats extends StatelessWidget {
  const _MiniStats({required this.ganador});
  final ClubvisionGanadorStats ganador;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        _StatChip(
          icon: '📖',
          label:
              '${ganador.lectoras}/${ganador.totalMiembros} lo leyeron',
          color: const Color(0xFF4A9E4A),
        ),
        if (ganador.valoracionMedia != null)
          _StatChip(
            icon: '⭐',
            label: '${ganador.valoracionMedia!.toStringAsFixed(1)}/5',
            color: const Color(0xFFB48113),
          ),
        if (ganador.totalComentarios > 0)
          _StatChip(
            icon: '💬',
            label: '${ganador.totalComentarios}',
            color: const Color(0xFF4A6FBF),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .20)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _NotStarted extends StatefulWidget {
  const _NotStarted({
    required this.year,
    required this.saving,
    required this.onStart,
    required this.canAdmin,
  });
  final int year;
  final bool saving;
  final VoidCallback onStart;
  final bool canAdmin;

  @override
  State<_NotStarted> createState() => _NotStartedState();
}

class _NotStartedState extends State<_NotStarted> {
  Map<String, dynamic>? preview;
  bool loading = false;

  Future<void> _prepare() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final value = await ApiService().prepareClubBookOfYear(widget.year);
      if (mounted) setState(() => preview = value);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _linkHistorical(Map<dynamic, dynamic> unresolved) async {
    final books = (preview?['linkableBooks'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final selected = await showDialog<Map<dynamic, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vincular ${unresolved['title'] ?? 'lectura'}'),
        content: SizedBox(
          width: 420,
          child: books.isEmpty
              ? const Text(
                  'No hay libros disponibles en la biblioteca del club.',
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return ListTile(
                      title: Text(book['title']?.toString() ?? ''),
                      subtitle: Text(book['authorName']?.toString() ?? ''),
                      onTap: () => Navigator.pop(context, book),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (selected == null || loading) return;
    setState(() => loading = true);
    try {
      final value = await ApiService().linkClubBookOfYearHistoricalCandidate(
        year: widget.year,
        resultId: unresolved['resultId']?.toString() ?? '',
        bookId: selected['bookId']?.toString() ?? '',
      );
      if (mounted) setState(() => preview = value);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ClubCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: AppColors.gold,
              ),
              Text(
                'Edición ${widget.year} · No iniciada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Participan las lecturas oficiales elegidas por el club durante el año.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!widget.canAdmin)
                const Text(
                  'La votación todavía no ha comenzado.',
                  textAlign: TextAlign.center,
                )
              else if (preview == null)
                FilledButton(
                  onPressed: loading ? null : _prepare,
                  child: Text(
                    loading ? 'Preparando…' : 'Preparar candidaturas',
                  ),
                )
              else ...[
                Text(
                  preview!['message']?.toString() ?? '',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final candidate
                    in (preview!['candidates'] as List? ?? const [])
                        .whereType<Map>())
                  ListTile(
                    dense: true,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child:
                          candidate['coverUrl']?.toString().isNotEmpty == true
                          ? OptimizedNetworkImage(
                              url: candidate['coverUrl'].toString(),
                              width: 34,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(
                              width: 34,
                              height: 50,
                              child: Icon(Icons.menu_book_outlined),
                            ),
                    ),
                    title: Text(candidate['title']?.toString() ?? ''),
                    subtitle: Text(
                      [
                        candidate['authorName']?.toString() ?? '',
                        if (candidate['source'] == 'CLUBVISION')
                          'Clubvisión · ${candidate['clubvisionEdition']}',
                        if (candidate['source'] == 'OFFICIAL_READING')
                          'Lectura oficial',
                      ].where((text) => text.isNotEmpty).join('\n'),
                    ),
                  ),
                for (final unresolved
                    in (preview!['unresolvedCandidates'] as List? ?? const [])
                        .whereType<Map>())
                  ListTile(
                    leading: const Icon(Icons.link_off_rounded),
                    title: Text(unresolved['title']?.toString() ?? ''),
                    subtitle: Text(
                      'Clubvisión · ${unresolved['edition']} · Pendiente de vincular',
                    ),
                    trailing: TextButton(
                      onPressed: loading
                          ? null
                          : () => _linkHistorical(unresolved),
                      child: const Text('Vincular'),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: loading ? null : _prepare,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Actualizar'),
                    ),
                    FilledButton(
                      onPressed: widget.saving || preview!['canStart'] != true
                          ? null
                          : widget.onStart,
                      child: const Text('Preparar edición'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _EditionHeader extends StatelessWidget {
  const _EditionHeader({required this.edition});
  final ClubBookOfYearEdition edition;
  @override
  Widget build(BuildContext context) => ClubCard(
    gradient: const LinearGradient(
      colors: [Color(0xFFF0E5F4), Color(0xFFFFF6DE)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
        Text(edition.clubName, style: Theme.of(context).textTheme.titleLarge),
        Text('${edition.year} · ${_status(edition.status)}'),
        if (edition.winner != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Libro ganador: ${edition.winner!.title}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
  static String _status(String value) =>
      const {
        'PREPARING': 'Preparando candidaturas',
        'QUALIFYING': 'Votación inicial',
        'ROUND_PENDING': 'Siguiente ronda preparada',
        'ROUND_OPEN': 'Ronda abierta · Vota ahora',
        'TIEBREAK': 'Desempate',
        'FINISHED': 'Finalizado',
      }[value] ??
      value;
}

class _Qualifying extends StatefulWidget {
  const _Qualifying({
    required this.edition,
    required this.saving,
    required this.onVote,
    this.onClose,
  });
  final ClubBookOfYearEdition edition;
  final bool saving;
  final ValueChanged<List<String>> onVote;
  final VoidCallback? onClose;
  @override
  State<_Qualifying> createState() => _QualifyingState();
}

class _QualifyingState extends State<_Qualifying> {
  late final Set<String> selected = {...widget.edition.myQualifyingVotes};
  late final Future<ClubvisionEstadisticas?> _statsFuture =
      ApiService().getClubvisionEstadisticas().then<ClubvisionEstadisticas?>(
        (s) => s,
        onError: (_) => null,
      );

  @override
  Widget build(BuildContext context) {
    final maxChoices = widget.edition.status == 'TIEBREAK' ? 1 : 3;
    return ClubCard(
      child: FutureBuilder<ClubvisionEstadisticas?>(
        future: _statsFuture,
        builder: (context, snap) {
          final stats = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votación clasificatoria',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                widget.edition.status == 'TIEBREAK'
                    ? 'Hay un empate en el corte. Elige un libro para resolverlo.'
                    : 'Elige hasta tres libros. Los resultados permanecerán ocultos hasta el cierre.',
              ),
              const SizedBox(height: AppSpacing.sm),
              // Acceso a estadísticas
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => const ClubvisionEstadisticasPage(),
                  ),
                ),
                icon: const Icon(Icons.bar_chart_rounded, size: 16),
                label: const Text('Ver estadísticas para decidir'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final candidate in widget.edition.candidates) ...[
                _QualifyingCandidate(
                  candidate: candidate,
                  selected: selected.contains(candidate.id),
                  enabled: !widget.saving,
                  maxChoices: maxChoices,
                  selectedCount: selected.length,
                  ganador: stats?.ganadores
                      .where((g) => g.bookId == candidate.bookId)
                      .firstOrNull,
                  onChanged: (checked) => setState(() {
                    if (checked == true && selected.length < maxChoices) {
                      selected.add(candidate.id);
                    } else if (checked == false) {
                      selected.remove(candidate.id);
                    }
                  }),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  FilledButton(
                    onPressed: widget.saving || selected.isEmpty
                        ? null
                        : () => widget.onVote(selected.toList()),
                    child: const Text('Guardar voto'),
                  ),
                  if (widget.onClose != null) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: widget.saving ? null : widget.onClose,
                      child: const Text('Cerrar clasificación'),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QualifyingCandidate extends StatelessWidget {
  const _QualifyingCandidate({
    required this.candidate,
    required this.selected,
    required this.enabled,
    required this.maxChoices,
    required this.selectedCount,
    required this.onChanged,
    this.ganador,
  });
  final ClubBookOfYearCandidate candidate;
  final bool selected;
  final bool enabled;
  final int maxChoices;
  final int selectedCount;
  final ClubvisionGanadorStats? ganador;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final canSelect = selected || selectedCount < maxChoices;
    return CheckboxListTile(
      value: selected,
      contentPadding: EdgeInsets.zero,
      title: Text(candidate.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(candidate.authorName),
          if (ganador != null) ...[
            const SizedBox(height: 4),
            _MiniStats(ganador: ganador!),
          ],
        ],
      ),
      onChanged: (enabled && (canSelect || selected)) ? onChanged : null,
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.round,
    required this.saving,
    required this.canAdmin,
    required this.onOpen,
    required this.onClose,
    required this.onVote,
  });
  final ClubBookOfYearRound round;
  final bool saving;
  final bool canAdmin;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final void Function(String, String) onVote;
  @override
  Widget build(BuildContext context) => ClubCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _phase(round.phase),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(round.status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final duel in round.duels)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                _DuelChoice(
                  candidate: duel.a,
                  selected: duel.myVoteCandidateId == duel.a.id,
                  enabled: round.status == 'OPEN' && !saving,
                  onTap: () => onVote(duel.id, duel.a.id),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('VS'),
                ),
                _DuelChoice(
                  candidate: duel.b,
                  selected: duel.myVoteCandidateId == duel.b.id,
                  enabled: round.status == 'OPEN' && !saving,
                  onTap: () => onVote(duel.id, duel.b.id),
                ),
              ],
            ),
          ),
        if (canAdmin && round.status == 'PENDING')
          FilledButton(
            onPressed: saving ? null : onOpen,
            child: const Text('Abrir ronda'),
          ),
        if (canAdmin && round.status == 'OPEN')
          OutlinedButton(
            onPressed: saving ? null : onClose,
            child: const Text('Cerrar ronda'),
          ),
      ],
    ),
  );
  static String _phase(String value) =>
      const {
        'QUARTERFINAL': 'Cuartos de final',
        'SEMIFINAL': 'Semifinal',
        'FINAL': 'Final',
        'TIEBREAK': 'Desempate',
      }[value] ??
      value;
}

class _DuelChoice extends StatelessWidget {
  const _DuelChoice({
    required this.candidate,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final ClubBookOfYearCandidate candidate;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            _Cover(candidate: candidate),
            Text(
              candidate.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
          ],
        ),
      ),
    ),
  );
}

class _Cover extends StatelessWidget {
  const _Cover({required this.candidate});
  final ClubBookOfYearCandidate candidate;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: candidate.coverUrl.isEmpty
        ? Container(
            width: 52,
            height: 76,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.menu_book),
          )
        : OptimizedNetworkImage(
            url: candidate.coverUrl,
            width: 52,
            height: 76,
            fit: BoxFit.cover,
          ),
  );
}
