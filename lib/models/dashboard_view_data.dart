import 'dashboard.dart';
import 'ranking_item.dart';

class DashboardViewData {
  final Dashboard dashboard;
  final bool haVotado;
  final List<RankingItem>? topLectoras;

  const DashboardViewData({
    required this.dashboard,
    required this.haVotado,
    required this.topLectoras,
  });
}
