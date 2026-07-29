import 'package:flutter/material.dart';

import '../../models/general_dashboard.dart';
import '../../theme/app_colors.dart';

class ReadingCoverCalendar extends StatelessWidget {
  const ReadingCoverCalendar({
    super.key,
    required this.calendar,
    this.onBookTap,
    this.showMonthHeader = true,
    this.cellAspectRatio = .72,
  });

  final ReadingCalendar calendar;
  final ValueChanged<MonthlyReadingSpan>? onBookTap;
  final bool showMonthHeader;
  final double cellAspectRatio;

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
                readings: readings,
                onBookTap: onBookTap,
              );
            },
          ),
        ),
      ],
    );
  }

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
    required this.readings,
    required this.onBookTap,
  });

  final int day;
  final List<MonthlyReadingSpan> readings;
  final ValueChanged<MonthlyReadingSpan>? onBookTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: readings.isEmpty
          ? 'Día $day, sin lectura registrada'
          : 'Día $day, ${readings.map((book) => book.title).join(', ')}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (readings.isEmpty)
            const ColoredBox(color: Color(0xFFFFFCF7))
          else
            Row(
              children: [
                for (final reading in readings.take(2))
                  Expanded(
                    child: GestureDetector(
                      onTap: onBookTap == null
                          ? null
                          : () => onBookTap!(reading),
                      child: _CalendarCover(reading: reading),
                    ),
                  ),
              ],
            ),
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
          if (readings.length > 2)
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
                  '+${readings.length - 2}',
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
}

class _CalendarCover extends StatelessWidget {
  const _CalendarCover({required this.reading});

  final MonthlyReadingSpan reading;

  @override
  Widget build(BuildContext context) {
    if (reading.coverUrl.trim().isEmpty) {
      return Container(
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
    }
    return Image.network(
      reading.coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(color: AppColors.primaryLight),
    );
  }
}
