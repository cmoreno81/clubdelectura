import 'package:flutter/material.dart';

import '../../models/configuracion_lectura.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

const _mesesCortos = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];
const _diasSemana = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// «sábado 18 oct» para una fecha `yyyy-MM-dd` (o el texto tal cual si no es válida).
String fechaLegible(String fecha) {
  final d = DateTime.tryParse(fecha);
  if (d == null) return fecha;
  return '${_diasSemana[d.weekday - 1]} ${d.day} ${_mesesCortos[d.month - 1]}';
}

String fechaIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Editor de las metas opcionales de una lectura conjunta: «hasta el capítulo
/// N, comentamos el día D». Sin metas la lectura funciona como siempre.
class EditorMetas extends StatelessWidget {
  const EditorMetas({
    super.key,
    required this.metas,
    required this.capitulos,
    required this.onChanged,
    this.habilitado = true,
  });

  final List<MetaLectura> metas;

  /// Capítulos de la lectura (para limitar el capítulo de cada meta).
  final int capitulos;
  final ValueChanged<List<MetaLectura>> onChanged;
  final bool habilitado;

  Future<void> _anadir(BuildContext context) async {
    final ultimo = metas.isEmpty
        ? 0
        : metas.map((m) => m.capitulo).reduce((a, b) => a > b ? a : b);
    final siguiente = (ultimo + 5).clamp(1, capitulos < 1 ? 1 : capitulos);
    final base = metas.isEmpty ? null : metas.last.dia;
    final hoy = DateTime.now();
    final inicial = (base ?? hoy).add(Duration(days: metas.isEmpty ? 7 : 7));
    final fecha = await _pedirFecha(context, inicial);
    if (fecha == null) return;
    onChanged(
      _ordenar([
        ...metas.where((m) => m.capitulo != siguiente),
        MetaLectura(capitulo: siguiente, fecha: fechaIso(fecha)),
      ]),
    );
  }

  Future<DateTime?> _pedirFecha(BuildContext context, DateTime inicial) {
    final hoy = DateTime.now();
    final primero = DateTime(hoy.year, hoy.month, hoy.day);
    return showDatePicker(
      context: context,
      initialDate: inicial.isBefore(primero) ? primero : inicial,
      firstDate: primero,
      lastDate: primero.add(const Duration(days: 730)),
      helpText: 'Día para comentar',
    );
  }

  List<MetaLectura> _ordenar(List<MetaLectura> lista) =>
      [...lista]..sort((a, b) => a.capitulo.compareTo(b.capitulo));

  @override
  Widget build(BuildContext context) {
    final ordenadas = _ordenar(metas);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ordenadas.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Sin metas: cada una lee a su ritmo, como siempre.',
              style: AppTextStyles.bodySecondary,
            ),
          ),
        for (var i = 0; i < ordenadas.length; i++)
          _FilaMeta(
            meta: ordenadas[i],
            desde: i == 0 ? 1 : ordenadas[i - 1].capitulo + 1,
            capitulos: capitulos,
            habilitado: habilitado,
            onCapitulo: (n) => onChanged(
              _ordenar([
                for (final m in ordenadas)
                  m == ordenadas[i]
                      ? MetaLectura(capitulo: n, fecha: m.fecha)
                      : m,
              ]),
            ),
            onFecha: () async {
              final nueva = await _pedirFecha(
                context,
                ordenadas[i].dia ?? DateTime.now(),
              );
              if (nueva == null) return;
              onChanged(
                _ordenar([
                  for (final m in ordenadas)
                    m == ordenadas[i]
                        ? MetaLectura(
                            capitulo: m.capitulo,
                            fecha: fechaIso(nueva),
                          )
                        : m,
                ]),
              );
            },
            onQuitar: () => onChanged([
              for (final m in ordenadas)
                if (m != ordenadas[i]) m,
            ]),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: habilitado && capitulos > 0 && ordenadas.length < 40
                ? () => _anadir(context)
                : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Añadir una meta'),
          ),
        ),
      ],
    );
  }
}

class _FilaMeta extends StatelessWidget {
  const _FilaMeta({
    required this.meta,
    required this.desde,
    required this.capitulos,
    required this.habilitado,
    required this.onCapitulo,
    required this.onFecha,
    required this.onQuitar,
  });

  final MetaLectura meta;
  final int desde;
  final int capitulos;
  final bool habilitado;
  final ValueChanged<int> onCapitulo;
  final VoidCallback onFecha;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text('Hasta el capítulo', style: AppTextStyles.body),
                DropdownButton<int>(
                  value: meta.capitulo.clamp(1, capitulos < 1 ? 1 : capitulos),
                  underline: const SizedBox.shrink(),
                  onChanged: habilitado
                      ? (n) => n == null ? null : onCapitulo(n)
                      : null,
                  items: [
                    for (var n = 1; n <= capitulos; n++)
                      DropdownMenuItem(value: n, child: Text('$n')),
                  ],
                ),
                ActionChip(
                  avatar: const Icon(Icons.event_rounded, size: 18),
                  label: Text(fechaLegible(meta.fecha)),
                  onPressed: habilitado ? onFecha : null,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar meta',
            onPressed: habilitado ? onQuitar : null,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
