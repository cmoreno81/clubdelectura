import '../models/dashboard_view_data.dart';
import 'api_service.dart';

class ClubDashboardService {
  ClubDashboardService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<DashboardViewData> load() async {
    final dashboard = await _api.getDashboard();
    return DashboardViewData(
      dashboard: dashboard,
      haVotado: dashboard.clubvision.haVotado,
      topLectoras: dashboard.topLectorasMes,
    );
  }
}
