import '../factories/estado_club_factory.dart';
import '../models/estado_club.dart';

class ClubNarrador {
  const ClubNarrador();

  EstadoClub narrar({required String estado}) {
    return EstadoClubFactory.fromApi(estado);
  }
}
