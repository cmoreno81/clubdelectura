import 'package:flutter/material.dart';
import '../../models/book_of_year.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/book_of_year_page.dart';
import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../common/club_card.dart';
import '../common/club_section_title.dart';
import '../common/optimized_network_image.dart';

class BookOfYearPreview extends StatelessWidget {
  const BookOfYearPreview({
    super.key,
    required this.profile,
    required this.editable,
  });
  final String profile;
  final bool editable;
  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final future = editable
        ? ApiService().getMyBookOfYear(year)
        : ApiService().getPublicBookOfYear(profile, year);
    return FutureBuilder<BookOfYearBoard>(
      future: future,
      builder: (context, snapshot) {
        final board = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (board == null || (!editable && !board.hasSelections)) {
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
              title: editable ? 'Mi libro del año' : 'Libro del año',
              subtitle: '$selections de 12 meses completados',
              icon: Icons.emoji_events_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClubCard(
              elevated: false,
              child: Column(
                children: [
                  if (board.winner != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _MiniCover(board.winner!),
                      title: Text(board.winner!.title),
                      subtitle: const Text('👑 Libro del año'),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.account_tree_outlined),
                      title: Text(
                        board.finalists.isEmpty
                            ? 'El cuadro está en marcha'
                            : '${board.finalists.length} finalistas actuales',
                      ),
                      subtitle: Text('$selections elecciones mensuales'),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        AppPageRoute(
                          builder: (_) => BookOfYearPage(
                            profile: editable ? null : profile,
                            initialYear: year,
                          ),
                        ),
                      ),
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

class _MiniCover extends StatelessWidget {
  const _MiniCover(this.book);
  final BookOfYearBook book;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: book.coverUrl.isEmpty
        ? Container(
            width: 38,
            height: 56,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.menu_book),
          )
        : OptimizedNetworkImage(
            url: book.coverUrl,
            width: 38,
            height: 56,
            fit: BoxFit.cover,
          ),
  );
}
