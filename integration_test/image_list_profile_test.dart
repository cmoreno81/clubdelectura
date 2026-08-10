import 'dart:io';
import 'dart:ui' as ui;

import 'package:club_lectura_app/widgets/common/club_book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('50+ portadas: carga fría/caliente, scroll y liberación', (
    tester,
  ) async {
    final pngs = await Future.wait([
      _coverPng(const Color(0xff6b4788)),
      _coverPng(const Color(0xffc96355)),
      _coverPng(const Color(0xff377a78)),
    ]);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <_RequestMetric>[];
    server.listen((request) async {
      final stopwatch = Stopwatch()..start();
      final index = int.tryParse(request.uri.pathSegments.last) ?? 0;
      var status = HttpStatus.ok;
      var bytes = pngs[index.abs() % pngs.length];
      if (request.uri.pathSegments.contains('corrupt')) {
        bytes = <int>[0, 1, 2, 3];
      }
      if (request.uri.pathSegments.contains('slow')) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(bytes);
      await request.response.close();
      stopwatch.stop();
      requests.add(
        _RequestMetric(
          provider: 'loopback-fixture',
          status: status,
          duration: stopwatch.elapsed,
          bytes: bytes.length,
        ),
      );
    });
    addTearDown(server.close);

    final baseUrl = 'http://${server.address.host}:${server.port}';
    final timings = <ui.FrameTiming>[];
    void collectTimings(List<ui.FrameTiming> values) => timings.addAll(values);
    WidgetsBinding.instance.addTimingsCallback(collectTimings);
    addTearDown(
      () => WidgetsBinding.instance.removeTimingsCallback(collectTimings),
    );

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    final rssBefore = ProcessInfo.currentRss;
    final firstFrameWatch = Stopwatch()..start();
    await tester.pumpWidget(MaterialApp(home: _CoverGallery(baseUrl: baseUrl)));
    await tester.pump();
    firstFrameWatch.stop();
    final firstUsefulFrame = firstFrameWatch.elapsed;
    await tester.pumpAndSettle();
    final coldRequests = requests.length;
    final coldRss = ProcessInfo.currentRss;

    await _scrollRoundTrip(tester);
    final afterColdScroll = requests.length;

    // Salir libera elementos/listeners. Volver simula caché caliente y permite
    // detectar providers que cambian de identidad en cada reconstrucción.
    final cycleRss = <int>[];
    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(home: _CoverGallery(baseUrl: baseUrl)),
      );
      await tester.pumpAndSettle();
      await _scrollRoundTrip(tester);
      cycleRss.add(ProcessInfo.currentRss);
    }
    final warmExtraRequests = requests.length - afterColdScroll;

    final slowFrames = timings
        .where((frame) => frame.totalSpan > const Duration(microseconds: 16667))
        .length;
    final worstUi = _maxDuration(timings.map((frame) => frame.buildDuration));
    final worstRaster = _maxDuration(
      timings.map((frame) => frame.rasterDuration),
    );
    final cache = PaintingBinding.instance.imageCache;
    final averageNetworkUs = requests.isEmpty
        ? 0
        : requests
                  .map((metric) => metric.duration.inMicroseconds)
                  .reduce((a, b) => a + b) ~/
              requests.length;
    final approximateBytes = requests.fold<int>(
      0,
      (total, metric) => total + metric.bytes,
    );
    final statuses = <int, int>{};
    for (final metric in requests) {
      statuses.update(metric.status, (value) => value + 1, ifAbsent: () => 1);
    }

    // Solo metadatos agregados; nunca se imprimen URLs completas.
    // ignore: avoid_print
    print(
      'COVER_PROFILE screen=cover-gallery items=60 visible=6 '
      'trigger=first-load+scroll+return resolved=true '
      'firstUsefulUs=${firstUsefulFrame.inMicroseconds} '
      'frames=${timings.length} slowFrames=$slowFrames '
      'worstUiUs=${worstUi.inMicroseconds} '
      'worstRasterUs=${worstRaster.inMicroseconds} '
      'rssBefore=$rssBefore coldRss=$coldRss cycleRss=$cycleRss '
      'cacheImages=${cache.currentSize} '
      'cacheBytes=${cache.currentSizeBytes} coldRequests=$coldRequests '
      'afterColdScroll=$afterColdScroll warmExtraRequests=$warmExtraRequests',
    );
    // ignore: avoid_print
    print(
      'COVER_NETWORK provider=loopback-fixture statuses=$statuses '
      'requests=${requests.length} averageDurationUs=$averageNetworkUs '
      'approxBytes=$approximateBytes',
    );

    expect(coldRequests, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

class _CoverGallery extends StatelessWidget {
  const _CoverGallery({required this.baseUrl});

  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        key: const Key('cover-gallery'),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: 60,
        itemBuilder: (_, index) {
          // 45 imágenes únicas, 10 placeholders sin red y 5 corruptas. Algunas
          // respuestas son lentas para comprobar que ninguna bloquea al resto.
          final hasNetworkImage = index % 6 != 0;
          final isCorrupt = index % 12 == 5;
          final isSlow = index % 10 == 3;
          final kind = isCorrupt
              ? 'corrupt'
              : isSlow
              ? 'slow'
              : 'cover';
          return ClubBookCover(
            key: ValueKey('cover-$index'),
            title: 'Libro $index',
            imageUrl: hasNetworkImage ? '$baseUrl/$kind/$index' : '',
            width: 72,
            height: 108,
            showShadow: false,
          );
        },
      ),
    );
  }
}

Future<void> _scrollRoundTrip(WidgetTester tester) async {
  final gallery = find.byKey(const Key('cover-gallery'));
  for (var index = 0; index < 10; index++) {
    await tester.fling(gallery, const Offset(0, -650), 1800);
    await tester.pumpAndSettle();
  }
  for (var index = 0; index < 10; index++) {
    await tester.fling(gallery, const Offset(0, 650), 1800);
    await tester.pumpAndSettle();
  }
}

Future<List<int>> _coverPng(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 900, 1350), Paint()..color = color);
  canvas.drawCircle(
    const Offset(450, 500),
    260,
    Paint()..color = const Color(0x55ffffff),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(900, 1350);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

Duration _maxDuration(Iterable<Duration> values) => values.fold<Duration>(
  Duration.zero,
  (maximum, value) => value > maximum ? value : maximum,
);

class _RequestMetric {
  const _RequestMetric({
    required this.provider,
    required this.status,
    required this.duration,
    required this.bytes,
  });

  final String provider;
  final int status;
  final Duration duration;
  final int bytes;
}
