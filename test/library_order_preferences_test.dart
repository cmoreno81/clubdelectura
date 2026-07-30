import 'package:club_lectura_app/services/library_order_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cada cuenta conserva su propio orden de biblioteca', () async {
    SharedPreferences.setMockInitialValues({});
    const preferences = LibraryOrderPreferences();

    await preferences.write('user-cristina', 'recientes');
    await preferences.write('user-ana', 'populares');

    expect(await preferences.read('user-cristina'), 'recientes');
    expect(await preferences.read('user-ana'), 'populares');
  });
}
