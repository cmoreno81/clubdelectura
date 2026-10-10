import 'package:flutter/material.dart';

import '../../services/reading_calendar_mode_service.dart';

/// Interruptor entre las dos formas de ver el calendario de lectura:
/// portada todos los días de la lectura, o solo el día que se terminó.
class CalendarModeToggle extends StatelessWidget {
  const CalendarModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ReadingCalendarModeService.soloDiaDeFin,
      builder: (context, soloDiaDeFin, _) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            segments: const [
              ButtonSegment(value: false, label: Text('Cada día')),
              ButtonSegment(value: true, label: Text('Al terminar')),
            ],
            selected: {soloDiaDeFin},
            onSelectionChanged: (valores) =>
                ReadingCalendarModeService.cambiar(valores.first),
          ),
        );
      },
    );
  }
}
