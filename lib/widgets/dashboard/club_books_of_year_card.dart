import 'package:flutter/material.dart';
import '../../models/book_of_year.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/book_of_year_page.dart';
import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';
import '../common/optimized_network_image.dart';

class ClubBooksOfYearCard extends StatefulWidget {
  const ClubBooksOfYearCard({super.key});
  @override
  State<ClubBooksOfYearCard> createState() => _ClubBooksOfYearCardState();
}

class _ClubBooksOfYearCardState extends State<ClubBooksOfYearCard> {
  late final int year = DateTime.now().year;
  late final Future<List<ClubBookOfYearMember>> future = ApiService()
      .getClubBooksOfYear(year);

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<ClubBookOfYearMember>>(
        future: future,
        builder: (context, snapshot) {
          final members = snapshot.data ?? const [];
          if (snapshot.connectionState != ConnectionState.done) {
            return const ClubCard(
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (members.isEmpty) return const SizedBox.shrink();
          return ClubCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Libros del año del club',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text('Los cuadros personales de tus compañeras'),
                const SizedBox(height: AppSpacing.sm),
                ...members.map(
                  (member) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClubAvatar(
                      nombre: member.userName,
                      imageUrl: member.avatarUrl,
                      size: 42,
                    ),
                    title: Text(member.userName),
                    subtitle: Text(
                      member.winner != null
                          ? '👑 ${member.winner!.title}'
                          : '${member.completedMonths}/12 meses · '
                                '${member.finalists.length} finalistas',
                    ),
                    trailing: member.winner != null
                        ? _Cover(member.winner!)
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push<void>(
                      context,
                      AppPageRoute(
                        builder: (_) => BookOfYearPage(
                          profile: member.userName,
                          initialYear: year,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _Cover extends StatelessWidget {
  const _Cover(this.book);
  final BookOfYearBook book;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: book.coverUrl.isEmpty
        ? Container(
            width: 30,
            height: 44,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.menu_book, size: 16),
          )
        : OptimizedNetworkImage(
            url: book.coverUrl,
            width: 30,
            height: 44,
            fit: BoxFit.cover,
          ),
  );
}
