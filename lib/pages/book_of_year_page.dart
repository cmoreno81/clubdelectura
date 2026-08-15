import 'package:flutter/material.dart';
import '../models/book_of_year.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/optimized_network_image.dart';

class BookOfYearPage extends StatefulWidget {
  const BookOfYearPage({
    super.key,
    this.profile,
    this.initialYear,
    this.loadBoard,
  });
  final String? profile;
  final int? initialYear;
  final Future<BookOfYearBoard> Function(int year, bool editable)? loadBoard;
  bool get editable => profile == null;
  @override
  State<BookOfYearPage> createState() => _BookOfYearPageState();
}

class _BookOfYearPageState extends State<BookOfYearPage> {
  late int _year = widget.initialYear ?? DateTime.now().year;
  late Future<BookOfYearBoard> _future = _load();
  bool _saving = false;
  Future<BookOfYearBoard> _load() =>
      widget.loadBoard?.call(_year, widget.editable) ??
      (widget.editable
          ? ApiService().getMyBookOfYear(_year)
          : ApiService().getPublicBookOfYear(widget.profile!, _year));
  void _changeYear(int year) => setState(() {
    _year = year;
    _future = _load();
  });

  Future<void> _chooseMonth(
    BookOfYearBoard board,
    BookOfYearMonth month,
  ) async {
    if (!board.editable || month.locked || _saving) return;
    if (month.eligible.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin lecturas')));
      return;
    }
    final choice = await showModalBottomSheet<BookOfYearBook>(
      context: context,
      useSafeArea: true,
      builder: (_) =>
          _BookPicker(title: _monthName(month.month), books: month.eligible),
    );
    if (choice == null || choice.id == month.selection?.id || !mounted) return;
    if (month.selection != null) {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cambiar elección mensual'),
              content: const Text(
                'Este cambio puede invalidar únicamente los duelos y finalistas que dependan de la elección anterior.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Cambiar'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed || !mounted) return;
    }
    await _mutate(
      () => ApiService().saveMonthlyBookOfYear(_year, month.month, choice.id),
    );
  }

  Future<void> _chooseDuel(BookOfYearDuel duel, BookOfYearBook book) => _mutate(
    () => ApiService().chooseBookOfYearDuel(
      _year,
      duel.phase,
      duel.position,
      book.id,
    ),
  );
  Future<void> _chooseWinner(BookOfYearBook book) =>
      _mutate(() => ApiService().chooseAnnualBookOfYear(_year, book.id));
  Future<void> _mutate(Future<BookOfYearBoard> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final board = await action();
      if (mounted) {
        setState(() => _future = Future.value(board));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Libro del año'),
      actions: [
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _year,
            items: List.generate(6, (i) => DateTime.now().year - i)
                .map(
                  (year) => DropdownMenuItem(value: year, child: Text('$year')),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) _changeYear(value);
                  },
          ),
        ),
      ],
    ),
    body: FutureBuilder<BookOfYearBoard>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo cargar el cuadro'),
                TextButton(
                  onPressed: () => setState(() => _future = _load()),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final board = snapshot.data!;
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  '${board.userName} · $_year',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Elecciones mensuales',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 400 ? 1 : 2;
                    final width = columns == 1
                        ? constraints.maxWidth
                        : (constraints.maxWidth - AppSpacing.sm) / 2;
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: board.months
                          .map(
                            (month) => SizedBox(
                              width: width,
                              child: _MonthCard(
                                month: month,
                                editable: board.editable,
                                onTap: () => _chooseMonth(board, month),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                _Round(
                  title: 'Primera ronda',
                  duels: board.duels
                      .where((d) => d.phase == 'MONTH_PAIR')
                      .toList(),
                  editable: board.editable,
                  onChoose: _chooseDuel,
                ),
                const SizedBox(height: AppSpacing.lg),
                _Round(
                  title: 'Ronda de finalistas',
                  duels: board.duels
                      .where((d) => d.phase == 'SEMIFINAL')
                      .toList(),
                  editable: board.editable,
                  onChoose: _chooseDuel,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Finalistas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (board.finalists.isEmpty)
                  const Text('Todavía no hay finalistas')
                else
                  ...board.finalists.map(
                    (book) => ListTile(
                      leading: _Cover(book: book, width: 34),
                      title: Text(book.title),
                      subtitle: Text(book.authorName),
                      onTap: board.editable && _year < DateTime.now().year
                          ? () => _chooseWinner(book)
                          : null,
                    ),
                  ),
                if (board.winner != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _Winner(book: board.winner!),
                ],
                const SizedBox(height: 40),
              ],
            ),
            if (_saving)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.month,
    required this.editable,
    required this.onTap,
  });
  final BookOfYearMonth month;
  final bool editable;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ClubCard(
    elevated: false,
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: InkWell(
      onTap: editable && !month.locked ? onTap : null,
      child: SizedBox(
        height: 112,
        child: Row(
          children: [
            _Cover(book: month.selection, width: 54, locked: month.locked),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _monthName(month.month),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (month.locked)
                    const Text('Bloqueado')
                  else if (month.selection != null)
                    Text(
                      month.selection!.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      month.eligible.isEmpty && month.finished
                          ? 'Sin lecturas'
                          : editable
                          ? 'Elegir +'
                          : 'Sin elección',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Round extends StatelessWidget {
  const _Round({
    required this.title,
    required this.duels,
    required this.editable,
    required this.onChoose,
  });

  final String title;
  final List<BookOfYearDuel> duels;
  final bool editable;
  final void Function(BookOfYearDuel, BookOfYearBook) onChoose;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      ...duels.map(
        (duel) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ClubCard(
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duelo ${duel.position}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (!duel.unlocked)
                  const Text(
                    'Bloqueado',
                    style: TextStyle(color: AppColors.textMuted),
                  )
                else if (duel.candidates.isEmpty)
                  const Text('Sin candidatas')
                else
                  Wrap(
                    spacing: 8,
                    children: duel.candidates
                        .map(
                          (book) => ChoiceChip(
                            label: Text(
                              book.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: duel.winner?.id == book.id,
                            onSelected: editable && duel.candidates.length > 1
                                ? (_) => onChoose(duel, book)
                                : null,
                          ),
                        )
                        .toList(),
                  ),
                if (duel.automatic)
                  const Text(
                    'Avance automático',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _Winner extends StatelessWidget {
  const _Winner({required this.book});
  final BookOfYearBook book;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .96, end: 1),
    duration: const Duration(milliseconds: 500),
    builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD76A), Color(0xFFFF9D66)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Text('👑', style: TextStyle(fontSize: 38)),
          _Cover(book: book, width: 110),
          const SizedBox(height: 8),
          Text(
            book.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(book.authorName),
        ],
      ),
    ),
  );
}

class _Cover extends StatelessWidget {
  const _Cover({required this.book, required this.width, this.locked = false});
  final BookOfYearBook? book;
  final double width;
  final bool locked;
  @override
  Widget build(BuildContext context) {
    final height = width * 1.5;
    if (locked) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.lock_outline),
      );
    }
    if (book == null || book!.coverUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(book == null ? Icons.add_rounded : Icons.menu_book),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: OptimizedNetworkImage(
        url: book!.coverUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _BookPicker extends StatelessWidget {
  const _BookPicker({required this.title, required this.books});
  final String title;
  final List<BookOfYearBook> books;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: books
                .map(
                  (book) => ListTile(
                    leading: _Cover(book: book, width: 34),
                    title: Text(book.title),
                    subtitle: Text(book.authorName),
                    onTap: () => Navigator.pop(context, book),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}

String _monthName(int month) => const [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
][month - 1];
