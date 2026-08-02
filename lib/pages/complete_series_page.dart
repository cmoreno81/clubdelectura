import 'package:flutter/material.dart';

import '../models/catalog_book.dart';
import '../models/perfil_usuario.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/library_refresh_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CompleteSeriesPage extends StatefulWidget {
  const CompleteSeriesPage({super.key, required this.series});

  final PerfilSaga series;

  @override
  State<CompleteSeriesPage> createState() => _CompleteSeriesPageState();
}

class _CompleteSeriesPageState extends State<CompleteSeriesPage> {
  late final TextEditingController _searchController;
  List<CatalogBook> _books = const [];
  bool _loading = true;
  String? _error;
  String? _linkingId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: [
        widget.series.nombre,
        widget.series.autor,
      ].where((value) => value.trim().isNotEmpty).join(' '),
    );
    _search();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await ApiService().getCatalogoGeneral(
        query: _searchController.text,
      );
      final linkedIds = widget.series.volumenes
          .map((volume) => volume.bookId)
          .toSet();
      if (mounted) {
        setState(() {
          _books = books
              .where((book) => !linkedIds.contains(book.id))
              .toList(growable: false);
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(CatalogBook book) async {
    final selection = await _askVolumeDetails(book);
    if (selection == null || !mounted) return;
    final order = selection.order;
    final normalizedOrder = order.trim().replaceAll(',', '.');

    final orderAlreadyExists = widget.series.volumenes.any(
      (volume) => volume.numero.trim().replaceAll(',', '.') == normalizedOrder,
    );

    if (orderAlreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El volumen $order ya existe en ${widget.series.nombre}.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _linkingId = book.id;
    });

    try {
      final linkedBookId = await ApiService().vincularVolumenSaga(
        sagaId: widget.series.id,
        numero: order,
        book: book,
        estado: selection.status,
        formato: selection.format,
        valoracion: selection.rating,
        fechaInicio: selection.startDate,
        fechaFin: selection.endDate,
      );

      LibraryRefreshNotifier.instance.invalidate();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} añadido a la saga')),
      );

      Navigator.pop(context, linkedBookId);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _linkingId = null;
        });
      }
    }
  }

  Future<_SeriesVolumeSelection?> _askVolumeDetails(CatalogBook book) async {
    var order = _suggestedOrder().toString();
    var status = 'PENDIENTE';
    var format = '';
    var rating = '';
    DateTime? startDate;
    DateTime? endDate;
    String? error;

    return showDialog<_SeriesVolumeSelection>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir volumen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: order,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) => order = value,
                  decoration: const InputDecoration(
                    labelText: 'Número en la saga',
                    hintText: '1, 2, 2.5…',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Estado de lectura',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'PENDIENTE',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(value: 'LEYENDO', child: Text('Leyendo')),
                    DropdownMenuItem(
                      value: 'FINALIZADO',
                      child: Text('Terminado'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      status = value;
                      error = null;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: format,
                  decoration: const InputDecoration(
                    labelText: 'Formato (opcional)',
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Sin indicar')),
                    DropdownMenuItem(value: 'FISICO', child: Text('Físico')),
                    DropdownMenuItem(value: 'DIGITAL', child: Text('Digital')),
                    DropdownMenuItem(
                      value: 'AUDIOLIBRO',
                      child: Text('Audiolibro'),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() {
                    format = value ?? '';
                  }),
                ),
                if (status != 'PENDIENTE') ...[
                  const SizedBox(height: AppSpacing.md),
                  _DateSelector(
                    label: 'Fecha de inicio (opcional)',
                    value: startDate,
                    onTap: () async {
                      final selected = await _pickDate(startDate);
                      if (selected != null) {
                        setDialogState(() => startDate = selected);
                      }
                    },
                  ),
                ],
                if (status == 'FINALIZADO') ...[
                  const SizedBox(height: AppSpacing.md),
                  _DateSelector(
                    label: 'Fecha de fin (opcional)',
                    value: endDate,
                    onTap: () async {
                      final selected = await _pickDate(endDate);
                      if (selected != null) {
                        setDialogState(() => endDate = selected);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: rating,
                    decoration: const InputDecoration(labelText: 'Valoración'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Selecciona')),
                      DropdownMenuItem(value: '1', child: Text('1 ★')),
                      DropdownMenuItem(value: '2', child: Text('2 ★')),
                      DropdownMenuItem(value: '3', child: Text('3 ★')),
                      DropdownMenuItem(value: '4', child: Text('4 ★')),
                      DropdownMenuItem(value: '5', child: Text('5 ★')),
                    ],
                    onChanged: (value) => setDialogState(() {
                      rating = value ?? '';
                      error = null;
                    }),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(error!, style: const TextStyle(color: AppColors.danger)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final cleanOrder = order.trim();
                if (cleanOrder.isEmpty) {
                  setDialogState(() => error = 'Indica el número del volumen.');
                  return;
                }
                if (status == 'FINALIZADO' && rating.isEmpty) {
                  setDialogState(() => error = 'Selecciona una valoración.');
                  return;
                }
                if (startDate != null &&
                    endDate != null &&
                    endDate!.isBefore(startDate!)) {
                  setDialogState(
                    () => error =
                        'La fecha de fin no puede ser anterior al inicio.',
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _SeriesVolumeSelection(
                    order: cleanOrder,
                    status: status,
                    format: format,
                    rating: rating,
                    startDate: _formatDate(startDate),
                    endDate: _formatDate(endDate),
                  ),
                );
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime? current) => showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int _suggestedOrder() {
    final numbers = widget.series.volumenes
        .map((volume) => double.tryParse(volume.numero.replaceAll(',', '.')))
        .whereType<double>()
        .where((value) => value == value.roundToDouble())
        .map((value) => value.toInt())
        .toSet();
    var candidate = 1;
    while (numbers.contains(candidate)) {
      candidate++;
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Completar ${widget.series.nombre}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(
                  'Busca y confirma únicamente los libros que pertenecen a esta saga.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SearchBar(
                  controller: _searchController,
                  leading: const Icon(Icons.search_rounded),
                  hintText: 'Saga, título o autora',
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _search(),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _books = const [];
                            _error = null;
                            _loading = false;
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    IconButton(
                      tooltip: 'Buscar',
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Escribe el título, la saga o la autora que quieres buscar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No encontramos más volúmenes. Puedes cambiar la búsqueda por el título concreto.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      itemCount: _books.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) {
        final book = _books[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.sm),
            leading: SizedBox(
              width: 48,
              height: 70,
              child: book.coverUrl.isEmpty
                  ? const Icon(Icons.auto_stories_outlined)
                  : Image.network(
                      book.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.auto_stories_outlined),
                    ),
            ),
            title: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('${book.authorLabel}\n${book.sourceLabel}'),
            isThreeLine: true,
            trailing: _linkingId == book.id
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filledTonal(
                    tooltip: 'Añadir a la saga',
                    onPressed: () => _select(book),
                    icon: const Icon(Icons.add_rounded),
                  ),
          ),
        );
      },
    );
  }
}

class _SeriesVolumeSelection {
  const _SeriesVolumeSelection({
    required this.order,
    required this.status,
    required this.format,
    required this.rating,
    required this.startDate,
    required this.endDate,
  });

  final String order;
  final String status;
  final String format;
  final String rating;
  final String startDate;
  final String endDate;
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        date == null
            ? 'Se usará la fecha de hoy'
            : '${date.day}/${date.month}/${date.year}',
      ),
      trailing: const Icon(Icons.calendar_month_rounded),
      onTap: onTap,
    );
  }
}
