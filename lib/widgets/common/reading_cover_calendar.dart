import 'package:flutter/material.dart';

import '../../models/general_dashboard.dart';
import '../../theme/app_colors.dart';
import 'optimized_network_image.dart';

class ReadingCoverCalendar extends StatelessWidget {
  const ReadingCoverCalendar({
    super.key,
    required this.calendar,
    this.onBookTap,
    this.showMonthHeader = true,
    this.cellAspectRatio = .72,
    this.highResolution = false,
  });

  final ReadingCalendar calendar;
  final ValueChanged<MonthlyReadingSpan>? onBookTap;
  final bool showMonthHeader;
  final double cellAspectRatio;
  final bool highResolution;

  static const _months = [
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
  ];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(calendar.year, calendar.month);
    final days = DateTime(calendar.year, calendar.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = ((offset + days + 6) ~/ 7) * 7;

    // Mapa "bookId|fecha" → rating para los libros terminados ese día.
    // Se indexa por libro Y fecha (no solo fecha) para que, si dos libros
    // terminan el mismo día, cada portada se quede con SU propia valoración
    // en vez de que una pise a la otra.
    final ratingsByBookAndDay = <String, double>{};
    for (final book in calendar.finishedBooks) {
      final finish = DateTime.tryParse(book.finishedAt)?.toLocal();
      if (finish == null) continue;
      final key = _finishKey(book.bookId, finish);
      if (book.rating != null && book.rating! > 0) {
        ratingsByBookAndDay[key] = book.rating!;
      } else {
        // Sin rating pero sí terminado → marcamos con 0 para poner la estrella vacía
        ratingsByBookAndDay.putIfAbsent(key, () => 0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMonthHeader) ...[
          Text(
            '${_months[calendar.month - 1]} ${calendar.year}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            for (final label in ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: cellAspectRatio,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemCount: cells,
            itemBuilder: (context, index) {
              final day = index - offset + 1;
              if (day < 1 || day > days) {
                return const ColoredBox(color: Color(0xFFF4EFE8));
              }
              final date = DateTime(calendar.year, calendar.month, day);
              final readings = calendar.readings
                  .where((reading) => _contains(reading, date))
                  .toList(growable: false);

              return _ReadingDayCell(
                day: day,
                date: date,
                readings: readings,
                ratingsByBookAndDay: ratingsByBookAndDay,
                onBookTap: onBookTap,
                highResolution: highResolution,
              );
            },
          ),
        ),
      ],
    );
  }

  static String _finishKey(String bookId, DateTime finish) =>
      '$bookId|${finish.year}-${finish.month}-${finish.day}';

  bool _contains(MonthlyReadingSpan reading, DateTime date) {
    final start = DateTime.tryParse(reading.startedAt)?.toLocal();
    final finish = DateTime.tryParse(reading.finishedAt)?.toLocal();
    if (start == null || finish == null) return false;
    final target = DateTime(date.year, date.month, date.day);
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(finish.year, finish.month, finish.day);
    return !target.isBefore(first) && !target.isAfter(last);
  }
}

class _ReadingDayCell extends StatelessWidget {
  const _ReadingDayCell({
    required this.day,
    required this.date,
    required this.readings,
    required this.onBookTap,
    required this.highResolution,
    required this.ratingsByBookAndDay,
  });

  final int day;
  final DateTime date;
  final List<MonthlyReadingSpan> readings;
  final ValueChanged<MonthlyReadingSpan>? onBookTap;
  final bool highResolution;

  /// "bookId|fecha" → rating, para poder darle a cada portada la suya
  /// cuando dos libros terminan el mismo día.
  final Map<String, double> ratingsByBookAndDay;

  double? _ratingFor(MonthlyReadingSpan reading) =>
      ratingsByBookAndDay[ReadingCoverCalendar._finishKey(reading.bookId, date)];

  // Cuántas portadas se abanican en la tarjeta para compartir antes de
  // recurrir al contador "+N" — con más se aprietan demasiado para leerse.
  static const _maxAbanico = 3;

  /// El libro que se termina ESE día va primero (delante, con su
  /// valoración bien visible); el que se está empezando va detrás, porque
  /// su portada se verá de sobra en los días siguientes que le dedique
  /// solo a él.
  List<MonthlyReadingSpan> get _ordenados {
    final terminados = <MonthlyReadingSpan>[];
    final enCurso = <MonthlyReadingSpan>[];
    for (final reading in readings) {
      (_ratingFor(reading) != null ? terminados : enCurso).add(reading);
    }
    return [...terminados, ...enCurso];
  }

  @override
  Widget build(BuildContext context) {
    final ordenados = _ordenados;
    final showFan = highResolution && readings.length > 1;
    final fanShown = showFan
        ? ordenados.take(_maxAbanico).toList()
        : const <MonthlyReadingSpan>[];
    final restantes = readings.length -
        (showFan ? fanShown.length : (readings.length > 1 ? 1 : readings.length));

    return Semantics(
      label: readings.isEmpty
          ? 'Día $day, sin lectura registrada'
          : 'Día $day, ${readings.map((book) => book.title).join(', ')}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (readings.isEmpty)
            const ColoredBox(color: Color(0xFFFFFCF7))
          else if (readings.length == 1)
            _portada(readings.first)
          else if (showFan)
            // Tarjeta para compartir: portadas abanicadas en diagonal, sin
            // interacción (es una imagen estática) — se ven casi enteras en
            // vez de aplastadas una junto a otra.
            _abanico(fanShown)
          else
            // Vista en la app: una sola portada representativa a tamaño
            // completo (el libro que se termina ese día, si lo hay); tocar
            // el día abre la lista de todos esos libros en vez de intentar
            // tocar una porción diminuta de cada portada.
            GestureDetector(
              onTap: onBookTap == null
                  ? null
                  : () => _mostrarLibrosDelDia(context),
              child: _portada(ordenados.first),
            ),

          // Número del día (círculo superior izquierdo)
          Positioned(
            left: 3,
            top: 3,
            child: Container(
              width: 21,
              height: 21,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: readings.isEmpty
                    ? Colors.white.withValues(alpha: .80)
                    : Colors.black.withValues(alpha: .62),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: readings.isEmpty
                      ? AppColors.textPrimary
                      : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          // Contador de libros que no caben a la vista
          if (restantes > 0)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$restantes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }

  Widget _portada(MonthlyReadingSpan reading) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _CalendarCover(reading: reading, highResolution: highResolution),
        if (_ratingFor(reading) != null)
          Positioned(
            right: 2,
            bottom: 2,
            child: _FinishBadge(rating: _ratingFor(reading)!),
          ),
      ],
    );
  }

  /// Portadas superpuestas en diagonal, la primera delante — pensado para
  /// una imagen estática (tarjeta para compartir), no para tocarla.
  Widget _abanico(List<MonthlyReadingSpan> shown) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = shown.length;
        // Más separación que antes (0.16 → 0.26) para que la de detrás se
        // reconozca de verdad, no solo un borde asomando.
        final step = constraints.maxWidth * 0.26;
        // Todas las portadas comparten el mismo tamaño reducido — si la de
        // delante ocupara la celda entera, taparía del todo a las de detrás.
        final coverW = constraints.maxWidth - (n - 1) * step;
        final coverH = constraints.maxHeight - (n - 1) * step * .6;
        return Stack(
          fit: StackFit.expand,
          children: [
            // 1) Las portadas, de atrás hacia delante.
            for (var i = n - 1; i >= 0; i--)
              Positioned(
                left: i * step,
                top: i * step * .6,
                width: coverW,
                height: coverH,
                child: Container(
                  decoration: BoxDecoration(
                    border: i > 0
                        ? Border.all(color: Colors.white, width: 1.4)
                        : null,
                  ),
                  child: _CalendarCover(
                    reading: shown[i],
                    highResolution: highResolution,
                  ),
                ),
              ),
            // 2) Las insignias de valoración, siempre ENCIMA de todas las
            // portadas — así la del libro de atrás nunca queda tapada por
            // la de delante, pase lo que pase con el orden de pintado.
            for (var i = 0; i < n; i++)
              if (_ratingFor(shown[i]) != null)
                Positioned(
                  left: i * step,
                  top: i * step * .6,
                  width: coverW,
                  height: coverH,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: _FinishBadge(rating: _ratingFor(shown[i])!),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarLibrosDelDia(BuildContext context) async {
    if (readings.length == 1) {
      onBookTap!(readings.first);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Día $day',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            for (final reading in readings)
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 36,
                    height: 52,
                    child: _CalendarCover(
                      reading: reading,
                      highResolution: false,
                    ),
                  ),
                ),
                title: Text(
                  reading.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onBookTap!(reading);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Badge compacto que aparece en el último día de lectura de un libro.
/// Muestra la valoración con media estrella si la hay, o solo un trofeo si no.
class _FinishBadge extends StatelessWidget {
  const _FinishBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final hasRating = rating > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .70),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasRating ? Icons.star_rounded : Icons.emoji_events_rounded,
            color: const Color(0xFFFFD700),
            size: 8,
          ),
          if (hasRating) ...[
            const SizedBox(width: 1),
            Text(
              // Muestra "4" o "4.5" sin decimales innecesarios
              rating == rating.roundToDouble()
                  ? rating.toInt().toString()
                  : rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarCover extends StatelessWidget {
  const _CalendarCover({required this.reading, required this.highResolution});

  final MonthlyReadingSpan reading;
  final bool highResolution;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(2),
      child: Text(
        reading.title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 7,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => OptimizedNetworkImage(
        url: reading.coverUrl,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        fallback: fallback,
        highResolution: highResolution,
      ),
    );
  }
}
