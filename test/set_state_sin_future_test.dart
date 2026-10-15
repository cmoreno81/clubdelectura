import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `setState(() => _future = algo())` devuelve el Future asignado y Flutter
/// (en modo debug) lanza «setState() callback argument returned a Future».
/// Crashlytics lo recibe de las ejecuciones de desarrollo. Se escribe con
/// llaves: `setState(() { _future = algo(); })`.
void main() {
  test('ningún setState con flecha devuelve un Future', () {
    final campoFuture = RegExp(
      r'(?:late\s+)?(?:final\s+)?Future(?:<[^;=]*?>)?\??\s+(_?\w+)\s*(?:;|=)',
    );
    final flecha = RegExp(r'setState\(\s*\(\)\s*=>\s*(_?\w+)\s*=\s*');
    final fallos = <String>[];

    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final texto = f.readAsStringSync();
      final nombres = campoFuture
          .allMatches(texto)
          .map((m) => m.group(1)!)
          .toSet();
      for (final m in flecha.allMatches(texto)) {
        if (nombres.contains(m.group(1))) {
          final linea = '\n'.allMatches(texto.substring(0, m.start)).length + 1;
          fallos.add('${f.path}:$linea (${m.group(1)})');
        }
      }
    }
    expect(fallos, isEmpty, reason: fallos.join('\n'));
  });
}
