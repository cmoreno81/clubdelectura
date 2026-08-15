import 'package:flutter/material.dart';
import '../models/book_of_year.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/book_of_year/book_of_year_bracket.dart';

class BookOfYearPage extends StatefulWidget {
  const BookOfYearPage({
    super.key,
    this.profile,
    this.initialYear,
    this.loadBoard,
    this.saveMonth,
    this.chooseDuel,
    this.chooseWinner,
  });
  final String? profile;
  final int? initialYear;
  final Future<BookOfYearBoard> Function(int year, bool editable)? loadBoard;
  final Future<BookOfYearBoard> Function(int year, int month, String bookId)?
  saveMonth;
  final Future<BookOfYearBoard> Function(
    int year,
    String phase,
    int position,
    String bookId,
  )?
  chooseDuel;
  final Future<BookOfYearBoard> Function(int year, String bookId)? chooseWinner;
  bool get editable => profile == null;
  @override
  State<BookOfYearPage> createState() => _BookOfYearPageState();
}

class _BookOfYearPageState extends State<BookOfYearPage> {
  late int _year = widget.initialYear ?? DateTime.now().year;
  late Future<BookOfYearBoard> _future = _load();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  BookOfYearBoard? _board;
  int? _positionedYear;
  bool _saving = false;
  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController.addListener(_updateHorizontalHint);
  }

  void _updateHorizontalHint() {
    if (!_horizontalScrollController.hasClients) return;
    final position = _horizontalScrollController.position;
    final shouldShow = position.pixels < position.maxScrollExtent - 1;
    if (shouldShow == _showRightFade || !mounted) return;
    setState(() => _showRightFade = shouldShow);
  }

  void _scheduleHorizontalHintUpdate() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateHorizontalHint(),
    );
  }

  Future<BookOfYearBoard> _load() =>
      widget.loadBoard?.call(_year, widget.editable) ??
      (widget.editable
          ? ApiService().getMyBookOfYear(_year)
          : ApiService().getPublicBookOfYear(widget.profile!, _year));
  void _changeYear(int year) {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.jumpTo(0);
    }
    setState(() {
      _year = year;
      _board = null;
      _future = _load();
    });
  }

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
      () =>
          widget.saveMonth?.call(_year, month.month, choice.id) ??
          ApiService().saveMonthlyBookOfYear(_year, month.month, choice.id),
    );
  }

  Future<void> _chooseDuel(BookOfYearDuel duel, BookOfYearBook book) => _mutate(
    () =>
        widget.chooseDuel?.call(_year, duel.phase, duel.position, book.id) ??
        ApiService().chooseBookOfYearDuel(
          _year,
          duel.phase,
          duel.position,
          book.id,
        ),
  );
  Future<void> _chooseWinner(BookOfYearBook book) => _mutate(
    () =>
        widget.chooseWinner?.call(_year, book.id) ??
        ApiService().chooseAnnualBookOfYear(_year, book.id),
  );
  Future<void> _mutate(Future<BookOfYearBoard> Function() action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    try {
      final board = await action();
      if (mounted) {
        setState(() {
          _board = board;
          _future = Future.value(board);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_readableError(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.removeListener(_updateHorizontalHint);
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
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
        if (snapshot.hasData) _board = snapshot.data;
        final board = snapshot.data ?? _board;
        if (board == null && snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || board == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo cargar el cuadro'),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _future = _load();
                    });
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        if (_positionedYear != _year && board.winner != null) {
          _positionedYear = _year;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_horizontalScrollController.hasClients) {
              _horizontalScrollController.jumpTo(
                _horizontalScrollController.position.maxScrollExtent,
              );
            }
          });
        }
        _scheduleHorizontalHintUpdate();
        return Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${board.userName} · $_year',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(
                        'Desliza para ver las rondas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Stack(
                    children: [
                      SingleChildScrollView(
                        key: const ValueKey('book-of-year-horizontal-scroll'),
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: BookOfYearBracket(
                          board: board,
                          year: _year,
                          onChooseMonth: (month) => _chooseMonth(board, month),
                          onChooseDuel: _chooseDuel,
                          onChooseWinner: _chooseWinner,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        width: 34,
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            key: const ValueKey('book-of-year-right-fade'),
                            opacity: _showRightFade ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Theme.of(context).scaffoldBackgroundColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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

// ignore: unused_element
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

// ignore: unused_element
class _Round extends StatelessWidget {
  const _Round({
    required this.title,
    required this.duels,
    required this.editable,
    required this.months,
    required this.onChoose,
  });

  final String title;
  final List<BookOfYearDuel> duels;
  final bool editable;
  final List<BookOfYearMonth> months;
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _duelTitle(duel),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _DuelStatus(duel: duel),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _slots(duel)
                      .map(
                        (slot) => _DuelSlot(
                          label: slot.$1,
                          book: slot.$2,
                          selected: duel.winner?.id == slot.$2?.id,
                          enabled:
                              editable &&
                              duel.unlocked &&
                              duel.candidates.isNotEmpty,
                          onTap: slot.$2 == null
                              ? null
                              : () => onChoose(duel, slot.$2!),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  String _duelTitle(BookOfYearDuel duel) {
    if (duel.phase != 'MONTH_PAIR') return 'Duelo ${duel.position}';
    final firstMonth = duel.position * 2 - 1;
    return '${_monthName(firstMonth)} vs ${_monthName(firstMonth + 1)}';
  }

  List<(String, BookOfYearBook?)> _slots(BookOfYearDuel duel) {
    if (duel.phase == 'MONTH_PAIR') {
      final firstMonth = duel.position * 2 - 1;
      return [
        (_monthName(firstMonth), months[firstMonth - 1].selection),
        (_monthName(firstMonth + 1), months[firstMonth].selection),
      ];
    }
    if (duel.candidates.isEmpty) {
      return const [('Libro 1', null), ('Libro 2', null)];
    }
    return List.generate(
      2,
      (index) => (
        'Libro ${index + 1}',
        index < duel.candidates.length ? duel.candidates[index] : null,
      ),
    );
  }
}

class _DuelStatus extends StatelessWidget {
  const _DuelStatus({required this.duel});
  final BookOfYearDuel duel;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = duel.winner != null
        ? ('Libro elegido', AppColors.success, Icons.check_circle_outline)
        : duel.unlocked
        ? (
            'Elige el libro ganador',
            AppColors.primary,
            Icons.how_to_vote_outlined,
          )
        : ('Bloqueado', AppColors.textMuted, Icons.lock_outline);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

class _DuelSlot extends StatelessWidget {
  const _DuelSlot({
    required this.label,
    required this.book,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final BookOfYearBook? book;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('duel-slot-$label-${book?.id ?? 'empty'}'),
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      width: 128,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _Cover(book: book, width: 42),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(
            book?.title ?? 'Sin selección',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: book == null ? AppColors.textMuted : null,
            ),
          ),
        ],
      ),
    ),
  );
}

// ignore: unused_element
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

String _readableError(Object error) {
  if (error is ApiException) return error.message;
  return error.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');
}
