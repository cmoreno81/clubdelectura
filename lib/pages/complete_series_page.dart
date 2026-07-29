import 'package:flutter/material.dart';

import '../models/catalog_book.dart';
import '../models/perfil_usuario.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
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
    final suggested = _suggestedOrder();
    final controller = TextEditingController(text: suggested.toString());
    final order = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Número en la saga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Volumen',
                hintText: '1, 2, 2.5…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (order == null || order.isEmpty || !mounted) return;

    setState(() => _linkingId = book.id);
    try {
      final linkedBookId = await ApiService().vincularVolumenSaga(
        sagaId: widget.series.id,
        numero: order,
        book: book,
      );
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
      if (mounted) setState(() => _linkingId = null);
    }
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
