// Tests de routing para openBookDetail y openCatalogBookDetail.
//
// Verifican que los parámetros forceFullDetail y globalStats producen
// la navegación correcta (CatalogBookDetailPage vs DetalleLibroPage)
// sin necesitar acceso a red real, inyectando fetchForTesting.

import 'package:club_lectura_app/models/libro.dart';
import 'package:club_lectura_app/models/libro_agrupado.dart';
import 'package:club_lectura_app/models/libro_finalizado.dart';
import 'package:club_lectura_app/navigation/book_detail_navigation.dart';
import 'package:club_lectura_app/pages/catalog_book_detail_page.dart';
import 'package:club_lectura_app/pages/detalle_libro_page.dart';
import 'package:club_lectura_app/services/atmosfera_controller.dart';
import 'package:club_lectura_app/services/atmosfera_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

Future<LibroPorIdData?> _fetchNull(String _) async => null;

Future<LibroPorIdData?> _fetchOtrosUsuarios(String _) async =>
    LibroPorIdData(libros: [_registroUsuario('maria')], finalizados: []);

Future<LibroPorIdData?> _fetchPropio(String _) async =>
    LibroPorIdData(libros: [_registroUsuario('cristina')], finalizados: []);

Libro _registroUsuario(String usuario) => Libro.fromJson({
  'bookId': 'book-test',
  'usuario': usuario,
  'libro': 'El príncipe cruel',
  'genero': 'Fantasía',
  'prioridad': 'MEDIA',
  'formato': 'FISICO',
  'estado': 'LEYENDO',
  'yaLoTengo': true,
  'coverUrl': '',
});

// ── Widget envoltorio con AtmosferaScope ─────────────────────────────────────
//
// DetalleLibroPage.initState accede a AtmosferaScope.of(context). Todos los
// tests que puedan navegar a DetalleLibroPage deben usar esta envoltura.

Widget _withScope({required Widget child}) {
  return AtmosferaScope(
    controller: AtmosferaController(),
    child: child,
  );
}

// ── Utilidad: pump y navega, devuelve el tipo del widget destino ──────────────

/// Ejecuta [action] en un contexto Flutter y devuelve el runtime type
/// del primer widget pusheado al navegador.
Future<Type?> _pumpAndNavigate(
  WidgetTester tester,
  Future<void> Function(BuildContext) action,
) async {
  Route<dynamic>? lastRoute;

  await tester.pumpWidget(
    _withScope(
      child: MaterialApp(
        navigatorObservers: [
          _RouteCapture(onPush: (r) => lastRoute = r),
        ],
        home: Builder(
          builder: (context) {
            // El microtask permite que el widget esté montado antes de navegar
            Future.microtask(() => action(context));
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  if (lastRoute == null) return null;
  // MaterialPageRoute<T> expone builder (hereda de PageRoute)
  try {
    final page = (lastRoute as MaterialPageRoute).builder(
      tester.element(find.byType(Scaffold).last),
    );
    return page.runtimeType;
  } catch (_) {
    return null;
  }
}

class _RouteCapture extends NavigatorObserver {
  _RouteCapture({required this.onPush});
  final void Function(Route<dynamic>) onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is MaterialPageRoute) onPush(route);
  }
}

// ── Setup ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    // AtmosferaController llama a SharedPreferences.getInstance() en su ctor.
    // Usamos valores vacíos para evitar MissingPluginException.
    SharedPreferences.setMockInitialValues({});
  });

  // ── Tests: openBookDetail ─────────────────────────────────────────────────

  group('openBookDetail', () {
    testWidgets('título vacío devuelve false sin navegar', (tester) async {
      SharedPreferences.setMockInitialValues({});
      var result = true;
      await tester.pumpWidget(
        _withScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                Future.microtask(() async {
                  result = await openBookDetail(
                    context,
                    title: '  ',
                    fetchForTesting: _fetchNull,
                  );
                });
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('resultado null → CatalogBookDetailPage', (tester) async {
      final pushed = await _pumpAndNavigate(
        tester,
        (ctx) => openBookDetail(
          ctx,
          title: 'El príncipe cruel',
          bookId: 'book-test',
          fetchForTesting: _fetchNull,
        ),
      );
      expect(pushed, CatalogBookDetailPage);
    });

    testWidgets('registros del usuario → DetalleLibroPage', (tester) async {
      final pushed = await _pumpAndNavigate(
        tester,
        (ctx) => openBookDetail(
          ctx,
          title: 'El príncipe cruel',
          bookId: 'book-test',
          fetchForTesting: _fetchPropio,
        ),
      );
      expect(pushed, DetalleLibroPage);
    });
  });

  // ── Tests: openCatalogBookDetail — tap simple ─────────────────────────────

  group('openCatalogBookDetail — tap (forceFullDetail=false)', () {
    testWidgets('resultado null → CatalogBookDetailPage', (tester) async {
      final pushed = await _pumpAndNavigate(
        tester,
        (ctx) => openCatalogBookDetail(
          ctx,
          title: 'El príncipe cruel',
          bookId: 'book-test',
          fetchForTesting: _fetchNull,
          usuarioActualForTesting: 'cristina',
        ),
      );
      expect(pushed, CatalogBookDetailPage);
    });

    testWidgets(
      'libro no en biblioteca del usuario (globalStats=false) → CatalogBookDetailPage',
      (tester) async {
        final pushed = await _pumpAndNavigate(
          tester,
          (ctx) => openCatalogBookDetail(
            ctx,
            title: 'El príncipe cruel',
            bookId: 'book-test',
            forceFullDetail: false,
            globalStats: false,
            fetchForTesting: _fetchOtrosUsuarios,
            usuarioActualForTesting: 'cristina',
          ),
        );
        expect(pushed, CatalogBookDetailPage);
      },
    );

    testWidgets(
      'usuario tiene el libro (globalStats=false) → DetalleLibroPage',
      (tester) async {
        final pushed = await _pumpAndNavigate(
          tester,
          (ctx) => openCatalogBookDetail(
            ctx,
            title: 'El príncipe cruel',
            bookId: 'book-test',
            forceFullDetail: false,
            globalStats: false,
            fetchForTesting: _fetchPropio,
            usuarioActualForTesting: 'cristina',
          ),
        );
        expect(pushed, DetalleLibroPage);
      },
    );
  });

  // ── Tests: openCatalogBookDetail — pulsación larga ────────────────────────

  group('openCatalogBookDetail — long press (forceFullDetail=true)', () {
    testWidgets(
      'resultado null + forceFullDetail → DetalleLibroPage',
      (tester) async {
        final pushed = await _pumpAndNavigate(
          tester,
          (ctx) => openCatalogBookDetail(
            ctx,
            title: 'El príncipe cruel',
            bookId: 'book-test',
            forceFullDetail: true,
            fetchForTesting: _fetchNull,
            usuarioActualForTesting: 'cristina',
          ),
        );
        expect(pushed, DetalleLibroPage);
      },
    );

    testWidgets(
      'libro no en biblioteca + forceFullDetail → DetalleLibroPage',
      (tester) async {
        final pushed = await _pumpAndNavigate(
          tester,
          (ctx) => openCatalogBookDetail(
            ctx,
            title: 'El príncipe cruel',
            bookId: 'book-test',
            forceFullDetail: true,
            globalStats: false,
            fetchForTesting: _fetchOtrosUsuarios,
            usuarioActualForTesting: 'cristina',
          ),
        );
        expect(pushed, DetalleLibroPage);
      },
    );

    testWidgets(
      'usuario tiene el libro + forceFullDetail → DetalleLibroPage',
      (tester) async {
        final pushed = await _pumpAndNavigate(
          tester,
          (ctx) => openCatalogBookDetail(
            ctx,
            title: 'El príncipe cruel',
            bookId: 'book-test',
            forceFullDetail: true,
            globalStats: false,
            fetchForTesting: _fetchPropio,
            usuarioActualForTesting: 'cristina',
          ),
        );
        expect(pushed, DetalleLibroPage);
      },
    );
  });

  // ── Tests: openCatalogBookDetail — globalStats ────────────────────────────

  group('openCatalogBookDetail — globalStats=true', () {
    testWidgets(
      'registros de otros + globalStats + forceFullDetail → DetalleLibroPage con total=1',
      (tester) async {
        DetalleLibroPage? destino;
        Route<dynamic>? lastRoute;

        await tester.pumpWidget(
          _withScope(
            child: MaterialApp(
              navigatorObservers: [
                _RouteCapture(onPush: (r) => lastRoute = r),
              ],
              home: Builder(
                builder: (context) {
                  Future.microtask(
                    () => openCatalogBookDetail(
                      context,
                      title: 'El príncipe cruel',
                      bookId: 'book-test',
                      forceFullDetail: true,
                      globalStats: true,
                      fetchForTesting: _fetchOtrosUsuarios,
                      usuarioActualForTesting: 'cristina',
                    ),
                  );
                  return const Scaffold(body: SizedBox.shrink());
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (lastRoute is MaterialPageRoute) {
          final page = (lastRoute as MaterialPageRoute).builder(
            tester.element(find.byType(Scaffold).last),
          );
          if (page is DetalleLibroPage) destino = page;
        }

        expect(destino, isNotNull);
        // Con globalStats=true se incluyen los registros de "maria"
        expect(destino!.libro.total, 1);
        // yaLoTengo es false porque "cristina" no tiene el libro
        expect(destino.libro.yaLoTengo, isFalse);
      },
    );

    testWidgets(
      'usuario tiene el libro + globalStats → yaLoTengo=true',
      (tester) async {
        DetalleLibroPage? destino;
        Route<dynamic>? lastRoute;

        await tester.pumpWidget(
          _withScope(
            child: MaterialApp(
              navigatorObservers: [
                _RouteCapture(onPush: (r) => lastRoute = r),
              ],
              home: Builder(
                builder: (context) {
                  Future.microtask(
                    () => openCatalogBookDetail(
                      context,
                      title: 'El príncipe cruel',
                      bookId: 'book-test',
                      forceFullDetail: true,
                      globalStats: true,
                      fetchForTesting: _fetchPropio,
                      usuarioActualForTesting: 'cristina',
                    ),
                  );
                  return const Scaffold(body: SizedBox.shrink());
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (lastRoute is MaterialPageRoute) {
          final page = (lastRoute as MaterialPageRoute).builder(
            tester.element(find.byType(Scaffold).last),
          );
          if (page is DetalleLibroPage) destino = page;
        }

        expect(destino?.libro.yaLoTengo, isTrue);
      },
    );

    testWidgets(
      'tap simple + globalStats + usuario no tiene libro → CatalogBookDetailPage',
      (tester) async {
        final pushed = await _pumpAndNavigate(
          tester,
          (ctx) => openCatalogBookDetail(
            ctx,
            title: 'El príncipe cruel',
            bookId: 'book-test',
            forceFullDetail: false,
            globalStats: true,
            fetchForTesting: _fetchOtrosUsuarios,
            usuarioActualForTesting: 'cristina',
          ),
        );
        expect(pushed, CatalogBookDetailPage);
      },
    );

    testWidgets(
      'tap simple + globalStats + usuario tiene libro → DetalleLibroPage',
      (tester) async {
        final pushed = await _pumpAndNavigate(
          tester,
          (ctx) => openCatalogBookDetail(
            ctx,
            title: 'El príncipe cruel',
            bookId: 'book-test',
            forceFullDetail: false,
            globalStats: true,
            fetchForTesting: _fetchPropio,
            usuarioActualForTesting: 'cristina',
          ),
        );
        expect(pushed, DetalleLibroPage);
      },
    );
  });

  // ── Tests: edge cases ─────────────────────────────────────────────────────

  group('openCatalogBookDetail — edge cases', () {
    testWidgets('título vacío devuelve false sin navegar', (tester) async {
      var result = true;
      await tester.pumpWidget(
        _withScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                Future.microtask(() async {
                  result = await openCatalogBookDetail(
                    context,
                    title: '',
                    fetchForTesting: _fetchNull,
                    usuarioActualForTesting: 'cristina',
                  );
                });
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('título solo espacios devuelve false', (tester) async {
      var result = true;
      await tester.pumpWidget(
        _withScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                Future.microtask(() async {
                  result = await openCatalogBookDetail(
                    context,
                    title: '   ',
                    fetchForTesting: _fetchNull,
                    usuarioActualForTesting: 'cristina',
                  );
                });
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}
