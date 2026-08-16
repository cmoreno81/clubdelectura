import 'package:flutter/material.dart';
import '../../models/book_of_year.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/book_of_year_page.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../book_of_year/book_of_year_bracket_preview.dart';
import '../common/club_card.dart';
import '../common/club_section_title.dart';

/// Tipo de error que ocurrió al cargar Libro del año público.
enum _BoyError {
  /// El identificador del perfil visitado es desconocido.
  missingIdentity,

  /// La cuenta con sesión no comparte club con el perfil visitado.
  noPermission,

  /// El perfil no existe en la base de datos.
  notFound,

  /// Error de red (sin conexión o timeout) — reintentar puede ayudar.
  network,

  /// Error temporal del servidor — reintentar puede ayudar.
  server,

  /// Cualquier otro error.
  unknown,
}

_BoyError _classify(Object error) {
  if (error is StateError) return _BoyError.missingIdentity;
  if (error is ApiException) {
    return switch (error.type) {
      ApiErrorType.forbidden => _BoyError.noPermission,
      ApiErrorType.noConnection || ApiErrorType.timeout => _BoyError.network,
      ApiErrorType.server => _BoyError.server,
      _ when error.code == 'USER_NOT_FOUND' => _BoyError.notFound,
      _ => _BoyError.unknown,
    };
  }
  return _BoyError.unknown;
}

class BookOfYearPreview extends StatefulWidget {
  const BookOfYearPreview({
    super.key,
    required this.profile,
    this.profileUserId,
    required this.editable,
    this.loadBoard,
    this.pageBuilder,
  });
  final String profile;
  final String? profileUserId;
  final bool editable;
  final Future<BookOfYearBoard> Function(int year, bool editable)? loadBoard;
  final Widget Function(int year, bool editable)? pageBuilder;

  @override
  State<BookOfYearPreview> createState() => _BookOfYearPreviewState();
}

class _BookOfYearPreviewState extends State<BookOfYearPreview> {
  late final int _year = DateTime.now().year;
  late Future<BookOfYearBoard> _future = _load();

  Future<BookOfYearBoard> _load() {
    // Capturamos excepciones síncronas para que siempre devolvamos un Future
    // controlado y evitamos que se propaguen como errores de build.
    try {
      if (widget.loadBoard != null) {
        return widget.loadBoard!(_year, widget.editable);
      }
      if (widget.editable) return ApiService().getMyBookOfYear(_year);

      // Para perfiles ajenos necesitamos al menos el nombre de perfil.
      // profileUserId es opcional: lo usamos para lookup por ID cuando está
      // disponible (más robusto), pero no bloqueamos si solo tenemos el nombre.
      final profileName = widget.profile.trim();
      if (profileName.isEmpty) {
        return Future.error(
          StateError('Falta el identificador estable del perfil visitado.'),
        );
      }
      return ApiService().getPublicBookOfYear(
        profileName,
        _year,
        profileUserId: widget.profileUserId?.trim(),
      );
    } catch (e, st) {
      return Future.error(e, st);
    }
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  void didUpdateWidget(covariant BookOfYearPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile ||
        oldWidget.profileUserId != widget.profileUserId ||
        oldWidget.editable != widget.editable) {
      _reload();
    }
  }

  Future<void> _openBoard() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) =>
            widget.pageBuilder?.call(_year, widget.editable) ??
            BookOfYearPage(
              profile: widget.editable ? null : widget.profile,
              profileUserId: widget.editable ? null : widget.profileUserId,
              initialYear: _year,
            ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookOfYearBoard>(
      future: _future,
      builder: (context, snapshot) {
        final board = snapshot.data;
        final done = snapshot.connectionState == ConnectionState.done;
        final selections = board?.months
                .where((m) => m.selection != null)
                .length ??
            0;
        final configured = board != null &&
            (board.hasSelections ||
                selections > 0 ||
                board.duels.isNotEmpty ||
                board.finalists.isNotEmpty ||
                board.winner != null);

        // Subtítulo: solo cuando hay datos configurados (no en carga, error ni vacío).
        final subtitle = (done && configured)
            ? '$selections de 12 meses elegidos'
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            ClubSectionTitle(
              title: widget.editable ? 'Mi libro del año' : 'Libro del año',
              subtitle: subtitle,
              icon: Icons.emoji_events_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!done)
              const ClubCard(
                elevated: false,
                child: SizedBox(
                  height: 72,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (snapshot.hasError)
              _ErrorCard(
                error: snapshot.error!,
                onRetry: _classify(snapshot.error!) != _BoyError.missingIdentity &&
                        _classify(snapshot.error!) != _BoyError.noPermission &&
                        _classify(snapshot.error!) != _BoyError.notFound
                    ? _reload
                    : null,
              )
            else if (!configured)
              ClubCard(
                key: const ValueKey('book-of-year-empty-state'),
                elevated: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.editable
                          ? 'Todavía no has comenzado tu Libro del año $_year'
                          : 'Todavía no ha comenzado su Libro del año $_year',
                    ),
                    if (widget.editable) ...[
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: _openBoard,
                        icon: const Icon(Icons.emoji_events_outlined),
                        label: const Text('Empezar mi Libro del año'),
                      ),
                    ],
                  ],
                ),
              )
            else
              ClubCard(
                elevated: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selections de 12 meses elegidos',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    BookOfYearBracketPreview(board: board, onTap: _openBoard),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _openBoard,
                        icon: const Icon(Icons.account_tree_outlined),
                        label: const Text('Ver cuadro completo'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de error con mensajes diferenciados
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final kind = _classify(error);
    final (title, message) = switch (kind) {
      _BoyError.missingIdentity => (
        'No se pudo identificar este perfil',
        'Vuelve atrás e intenta abrir el perfil de nuevo.',
      ),
      _BoyError.noPermission => (
        'Cuadro no disponible',
        'Solo las personas que comparten club pueden consultar este cuadro.',
      ),
      _BoyError.notFound => (
        'Perfil no encontrado',
        'Este perfil no existe o ya no está disponible.',
      ),
      _BoyError.network => (
        'Sin conexión',
        'Comprueba tu red e inténtalo de nuevo.',
      ),
      _BoyError.server => (
        'Error temporal',
        'El servidor no está disponible ahora mismo. Inténtalo más tarde.',
      ),
      _BoyError.unknown => (
        'No se pudo cargar Libro del año',
        'Se ha producido un error inesperado. Inténtalo de nuevo.',
      ),
    };

    return ClubCard(
      elevated: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text(message),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
