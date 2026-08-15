import 'package:flutter/material.dart';
import '../../models/book_of_year.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/book_of_year_page.dart';
import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../book_of_year/book_of_year_bracket_preview.dart';
import '../common/club_card.dart';
import '../common/club_section_title.dart';

class BookOfYearPreview extends StatefulWidget {
  const BookOfYearPreview({
    super.key,
    required this.profile,
    required this.editable,
    this.loadBoard,
    this.pageBuilder,
  });
  final String profile;
  final bool editable;
  final Future<BookOfYearBoard> Function(int year, bool editable)? loadBoard;
  final Widget Function(int year, bool editable)? pageBuilder;

  @override
  State<BookOfYearPreview> createState() => _BookOfYearPreviewState();
}

class _BookOfYearPreviewState extends State<BookOfYearPreview> {
  late final int _year = DateTime.now().year;
  late Future<BookOfYearBoard> _future = _load();

  Future<BookOfYearBoard> _load() =>
      widget.loadBoard?.call(_year, widget.editable) ??
      (widget.editable
          ? ApiService().getMyBookOfYear(_year)
          : ApiService().getPublicBookOfYear(widget.profile, _year));

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  void didUpdateWidget(covariant BookOfYearPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile ||
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
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (board == null || (!widget.editable && !board.hasSelections)) {
          return const SizedBox.shrink();
        }
        final selections = board.months
            .where((month) => month.selection != null)
            .length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            ClubSectionTitle(
              title: widget.editable ? 'Mi libro del año' : 'Libro del año',
              subtitle: '$selections de 12 meses elegidos',
              icon: Icons.emoji_events_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
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
