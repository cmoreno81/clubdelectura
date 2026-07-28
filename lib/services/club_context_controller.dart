import 'package:flutter/foundation.dart';

class ClubContextController extends ChangeNotifier {
  ClubContextController._();

  static final ClubContextController instance = ClubContextController._();

  void refresh() => notifyListeners();
}
