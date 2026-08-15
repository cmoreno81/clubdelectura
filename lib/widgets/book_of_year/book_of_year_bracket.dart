import 'package:flutter/material.dart';

import '../../models/book_of_year.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../common/optimized_network_image.dart';

class BookOfYearBracket extends StatelessWidget {
  const BookOfYearBracket({
    super.key,
    required this.board,
    required this.year,
    required this.onChooseMonth,
    required this.onChooseDuel,
    required this.onChooseWinner,
  });

  final BookOfYearBoard board;
  final int year;
  final ValueChanged<BookOfYearMonth> onChooseMonth;
  final void Function(BookOfYearDuel, BookOfYearBook) onChooseDuel;
  final ValueChanged<BookOfYearBook> onChooseWinner;

  static const size = Size(1120, 1365);

  @override
  Widget build(BuildContext context) {
    final first = _duels('MONTH_PAIR', 6);
    final semifinals = _duels('SEMIFINAL', 3);
    return Semantics(
      label: 'Cuadro eliminatorio de Libro del año $year',
      child: SizedBox.fromSize(
        size: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                key: const ValueKey('book-of-year-connections'),
                painter: _BracketConnectionsPainter(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .42),
                ),
              ),
            ),
            ..._columnTitles(context),
            for (var i = 0; i < 12; i++)
              Positioned(
                left: _Layout.monthX,
                top: _Layout.monthTop(i),
                child: _MonthSlot(
                  month: board.months[i],
                  editable: board.editable,
                  onTap: () => onChooseMonth(board.months[i]),
                ),
              ),
            for (var i = 0; i < 6; i++)
              Positioned(
                left: _Layout.firstX,
                top: _Layout.firstTop(i),
                child: _DuelNode(
                  key: ValueKey('bracket-first-${i + 1}'),
                  label:
                      '${_monthShort(i * 2 + 1)} · ${_monthShort(i * 2 + 2)}',
                  duel: first[i],
                  editable: board.editable,
                  onChoose: onChooseDuel,
                ),
              ),
            for (var i = 0; i < 3; i++)
              Positioned(
                left: _Layout.semiX,
                top: _Layout.semiTop(i),
                child: _DuelNode(
                  key: ValueKey('bracket-finalist-${i + 1}'),
                  label: 'Finalista ${i + 1}',
                  duel: semifinals[i],
                  editable: board.editable,
                  onChoose: onChooseDuel,
                ),
              ),
            Positioned(
              left: _Layout.winnerX,
              top: _Layout.winnerTop,
              child: _AnnualNode(
                finalists: board.finalists,
                winner: board.winner,
                enabled: board.editable && year < DateTime.now().year,
                onChoose: onChooseWinner,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BookOfYearDuel?> _duels(String phase, int count) =>
      List.generate(count, (index) {
        for (final duel in board.duels) {
          if (duel.phase == phase && duel.position == index + 1) return duel;
        }
        return null;
      });

  List<Widget> _columnTitles(BuildContext context) {
    Widget title(String text, double left, double width) => Positioned(
      left: left,
      top: 10,
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
    return [
      title('Meses', _Layout.monthX, _Layout.monthWidth),
      title('Primera ronda', _Layout.firstX, _Layout.duelWidth),
      title('Finalistas', _Layout.semiX, _Layout.duelWidth),
      title('Libro del año', _Layout.winnerX, _Layout.winnerWidth),
    ];
  }
}

class _Layout {
  static const monthX = 20.0;
  static const monthWidth = 190.0;
  static const firstX = 290.0;
  static const semiX = 570.0;
  static const winnerX = 850.0;
  static const duelWidth = 210.0;
  static const winnerWidth = 240.0;
  static const monthStart = 54.0;
  static const monthStep = 108.0;
  static const monthHeight = 88.0;
  static const duelHeight = 132.0;
  static const winnerTop = 510.0;

  static double monthTop(int index) => monthStart + index * monthStep;
  static double monthCenter(int index) => monthTop(index) + monthHeight / 2;
  static double firstCenter(int index) =>
      (monthCenter(index * 2) + monthCenter(index * 2 + 1)) / 2;
  static double firstTop(int index) => firstCenter(index) - duelHeight / 2;
  static double semiCenter(int index) =>
      (firstCenter(index * 2) + firstCenter(index * 2 + 1)) / 2;
  static double semiTop(int index) => semiCenter(index) - duelHeight / 2;
}

class _MonthSlot extends StatelessWidget {
  const _MonthSlot({
    required this.month,
    required this.editable,
    required this.onTap,
  });
  final BookOfYearMonth month;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = editable && !month.locked;
    return _BracketSlot(
      key: ValueKey('bracket-month-${month.month}'),
      label: _monthShort(month.month),
      book: month.selection,
      pending: month.selection == null,
      locked: month.locked,
      selected: month.selection != null,
      enabled: enabled,
      semanticLabel: month.selection == null
          ? '${_monthName(month.month)} pendiente'
          : '${_monthName(month.month)}: ${month.selection!.title}. Toca para cambiar',
      onTap: onTap,
    );
  }
}

class _DuelNode extends StatelessWidget {
  const _DuelNode({
    super.key,
    required this.label,
    required this.duel,
    required this.editable,
    required this.onChoose,
  });
  final String label;
  final BookOfYearDuel? duel;
  final bool editable;
  final void Function(BookOfYearDuel, BookOfYearBook) onChoose;

  @override
  Widget build(BuildContext context) {
    final item = duel;
    final locked = item == null || !item.unlocked;
    final candidates = item?.candidates ?? const <BookOfYearBook>[];
    return Container(
      width: _Layout.duelWidth,
      height: _Layout.duelHeight,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (locked)
                const Icon(
                  Icons.lock_outline,
                  size: 15,
                  color: AppColors.textMuted,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: candidates.isEmpty
                ? const _PendingContent(locked: true)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: candidates.take(2).map((book) {
                      final selected = item?.winner?.id == book.id;
                      return _Candidate(
                        key: ValueKey(
                          'bracket-duel-${item!.phase}-${item.position}-${book.id}',
                        ),
                        book: book,
                        selected: selected,
                        enabled: editable && !locked,
                        onTap: () => onChoose(item, book),
                      );
                    }).toList(),
                  ),
          ),
          Text(
            item?.winner != null
                ? 'Libro elegido'
                : locked
                ? 'Bloqueada'
                : 'Pendiente',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: item?.winner != null
                  ? AppColors.success
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnualNode extends StatelessWidget {
  const _AnnualNode({
    required this.finalists,
    required this.winner,
    required this.enabled,
    required this.onChoose,
  });
  final List<BookOfYearBook> finalists;
  final BookOfYearBook? winner;
  final bool enabled;
  final ValueChanged<BookOfYearBook> onChoose;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('bracket-annual-winner'),
    width: _Layout.winnerWidth,
    height: 280,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      gradient: winner == null
          ? null
          : const LinearGradient(
              colors: [Color(0xFFFFF2BF), Color(0xFFFFD9C7)],
            ),
      color: winner == null ? AppColors.surface : null,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(
        color: winner == null ? AppColors.border : const Color(0xFFE6AE35),
        width: 2,
      ),
    ),
    child: Column(
      children: [
        const Text(
          '👑',
          style: TextStyle(fontSize: 34),
          semanticsLabel: 'Corona',
        ),
        if (winner != null) ...[
          _BracketCover(book: winner, width: 76),
          const SizedBox(height: 6),
          Text(
            winner!.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ] else ...[
          const Expanded(child: _PendingContent(locked: false)),
          const Text(
            'Pendiente',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (finalists.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: finalists
                .map(
                  (book) => _Candidate(
                    book: book,
                    selected: winner?.id == book.id,
                    enabled: enabled,
                    compact: true,
                    onTap: () => onChoose(book),
                  ),
                )
                .toList(),
          ),
      ],
    ),
  );
}

class _BracketSlot extends StatelessWidget {
  const _BracketSlot({
    super.key,
    required this.label,
    required this.book,
    required this.pending,
    required this.locked,
    required this.selected,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });
  final String label;
  final BookOfYearBook? book;
  final bool pending;
  final bool locked;
  final bool selected;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: enabled,
    selected: selected,
    label: semanticLabel,
    child: CustomPaint(
      painter: pending && !locked
          ? _DashedBorderPainter(color: AppColors.border)
          : null,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: _Layout.monthWidth,
          height: _Layout.monthHeight,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : pending && !locked
                  ? Colors.transparent
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              _BracketCover(book: book, width: 42, locked: locked),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      locked
                          ? 'Bloqueado'
                          : pending
                          ? 'Pendiente'
                          : book!.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: pending || locked
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Candidate extends StatelessWidget {
  const _Candidate({
    super.key,
    required this.book,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.compact = false,
  });
  final BookOfYearBook book;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    button: enabled,
    selected: selected,
    label:
        '${book.title}${selected ? ', libro elegido' : ', candidatura disponible'}',
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        width: compact ? 52 : 84,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BracketCover(book: book, width: compact ? 28 : 34),
            if (!compact)
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
    ),
  );
}

class _PendingContent extends StatelessWidget {
  const _PendingContent({required this.locked});
  final bool locked;
  @override
  Widget build(BuildContext context) => CustomPaint(
    key: ValueKey(locked ? 'bracket-locked-slot' : 'bracket-pending-slot'),
    painter: _DashedBorderPainter(color: AppColors.border),
    child: Center(
      child: Icon(
        locked ? Icons.lock_outline : Icons.add_rounded,
        color: AppColors.textMuted,
      ),
    ),
  );
}

class _BracketCover extends StatelessWidget {
  const _BracketCover({
    required this.book,
    required this.width,
    this.locked = false,
  });
  final BookOfYearBook? book;
  final double width;
  final bool locked;
  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    if (locked || book == null || book!.coverUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(
          locked
              ? Icons.lock_outline
              : book == null
              ? Icons.add_rounded
              : Icons.menu_book_outlined,
          size: width * .42,
          color: AppColors.textMuted,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: OptimizedNetworkImage(
        url: book!.coverUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _BracketConnectionsPainter extends CustomPainter {
  const _BracketConnectionsPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    void connect(Offset from, Offset to) {
      final middle = (from.dx + to.dx) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(middle, from.dy)
          ..lineTo(middle, to.dy)
          ..lineTo(to.dx, to.dy),
        paint,
      );
    }

    for (var i = 0; i < 6; i++) {
      final target = Offset(_Layout.firstX, _Layout.firstCenter(i));
      connect(
        Offset(_Layout.monthX + _Layout.monthWidth, _Layout.monthCenter(i * 2)),
        target,
      );
      connect(
        Offset(
          _Layout.monthX + _Layout.monthWidth,
          _Layout.monthCenter(i * 2 + 1),
        ),
        target,
      );
    }
    for (var i = 0; i < 3; i++) {
      final target = Offset(_Layout.semiX, _Layout.semiCenter(i));
      connect(
        Offset(_Layout.firstX + _Layout.duelWidth, _Layout.firstCenter(i * 2)),
        target,
      );
      connect(
        Offset(
          _Layout.firstX + _Layout.duelWidth,
          _Layout.firstCenter(i * 2 + 1),
        ),
        target,
      );
      connect(
        Offset(_Layout.semiX + _Layout.duelWidth, _Layout.semiCenter(i)),
        Offset(_Layout.winnerX, _Layout.winnerTop + 140),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectionsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      );
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 10) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 5).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

String _monthShort(int month) => const [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
][month - 1];
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
