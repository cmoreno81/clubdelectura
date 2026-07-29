import 'package:flutter/material.dart';

import '../models/catalog_book.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ExploreCatalogPage extends StatefulWidget {
  const ExploreCatalogPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<ExploreCatalogPage> createState() => _ExploreCatalogPageState();
}

class _ExploreCatalogPageState extends State<ExploreCatalogPage> {
  late final TextEditingController _searchController;
  List<CatalogBook> _books = const [];
  bool _loading = true;
  String? _error;
  String? _addingId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _load(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load([String query = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await ApiService().getCatalogoGeneral(query: query);
      if (mounted) setState(() => _books = books);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se ha podido cargar la biblioteca.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(CatalogBook book) async {
    final preferences = await showModalBottomSheet<_BookPreferences>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddBookSheet(),
    );
    if (preferences == null || !mounted) return;
    setState(() => _addingId = book.id);
    try {
      await ApiService().importarLibroCatalogo(
        book: book,
        prioridad: preferences.priority,
        formato: preferences.format,
      );
      if (!mounted) return;
      setState(() {
        _books = _books
            .map(
              (item) => item.id == book.id && item.source == book.source
                  ? item.copyWith(inMyLibrary: true, status: 'PENDIENTE')
                  : item,
            )
            .toList(growable: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} está ya en tu biblioteca')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Explorar libros')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Título, autora o ISBN',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Borrar',
                    onPressed: () {
                      _searchController.clear();
                      _load();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
              onChanged: (_) => setState(() {}),
              onSubmitted: _load,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => _load(_searchController.text),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No encontramos ese libro. Prueba con el título o el ISBN.',
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
      itemBuilder: (_, index) => _bookCard(_books[index]),
    );
  }

  Widget _bookCard(CatalogBook book) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 94,
                child: book.coverUrl.isEmpty
                    ? Container(
                        color: AppColors.primary.withValues(alpha: .1),
                        child: const Icon(Icons.auto_stories_outlined),
                      )
                    : Image.network(
                        book.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.auto_stories_outlined),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.authorLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.sourceLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (book.inMyLibrary)
              const Tooltip(
                message: 'Ya está en tu biblioteca',
                child: Icon(
                  Icons.bookmark_added_rounded,
                  color: AppColors.success,
                ),
              )
            else if (_addingId == book.id)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton.filledTonal(
                tooltip: 'Añadir a mi biblioteca',
                onPressed: () => _add(book),
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookPreferences {
  const _BookPreferences(this.priority, this.format);
  final String priority;
  final String format;
}

class _AddBookSheet extends StatefulWidget {
  const _AddBookSheet();

  @override
  State<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<_AddBookSheet> {
  String _priority = 'MEDIA';
  String _format = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Añadir a mi biblioteca',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Prioridad'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: ['ALTA', 'MEDIA', 'BAJA']
                  .map(
                    (value) => ChoiceChip(
                      label: Text(value[0] + value.substring(1).toLowerCase()),
                      selected: _priority == value,
                      selectedColor: AppColors.primaryDark,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _priority == value
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: _priority == value
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _priority = value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Formato (puedes decidirlo más tarde)'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children:
                  const {
                        '': 'Sin decidir',
                        'FISICO': 'Físico',
                        'DIGITAL': 'Digital',
                        'AUDIOLIBRO': 'Audiolibro',
                      }.entries
                      .map(
                        (entry) => ChoiceChip(
                          label: Text(entry.value),
                          selected: _format == entry.key,
                          selectedColor: AppColors.primaryDark,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _format == entry.key
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: _format == entry.key
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                          onSelected: (_) =>
                              setState(() => _format = entry.key),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  _BookPreferences(_priority, _format),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
