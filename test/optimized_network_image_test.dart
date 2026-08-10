import 'package:club_lectura_app/widgets/common/club_avatar.dart';
import 'package:club_lectura_app/widgets/common/club_book_cover.dart';
import 'package:club_lectura_app/widgets/common/optimized_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('una URL vacía usa el fallback de portada y avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            ClubBookCover(title: 'Sin portada', imageUrl: '', width: 60),
            ClubAvatar(nombre: 'Ada Lovelace', imageUrl: '', size: 40),
          ],
        ),
      ),
    );

    expect(find.text('Sin portada'), findsOneWidget);
    expect(find.text('AL'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('un avatar sin foto muestra iniciales coherentes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClubAvatar(nombre: 'Ada Lovelace', imageUrl: null, size: 40),
      ),
    );

    expect(find.text('AL'), findsOneWidget);
    expect(find.text('?'), findsNothing);
  });

  testWidgets('un avatar sin identidad durante la carga es neutro', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClubAvatar(
          nombre: '',
          imageUrl: '',
          size: 40,
          neutralWhenUnnamed: true,
        ),
      ),
    );

    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.text('?'), findsNothing);
  });

  testWidgets('un avatar con foto la intenta cargar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClubAvatar(
          nombre: 'Ada Lovelace',
          imageUrl: 'https://example.invalid/ada.jpg',
          size: 40,
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('AL'), findsNothing);
  });

  testWidgets('un error de avatar vuelve a las iniciales', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClubAvatar(
          nombre: 'Ada Lovelace',
          imageUrl: 'https://example.invalid/ada.jpg',
          size: 40,
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final fallback = image.errorBuilder!(
      tester.element(find.byType(Image)),
      StateError('fallo simulado'),
      null,
    );

    await tester.pumpWidget(MaterialApp(home: fallback));
    expect(find.text('AL'), findsOneWidget);
    expect(find.text('?'), findsNothing);
  });

  testWidgets('muestra el placeholder durante la descarga', (tester) async {
    const placeholderKey = Key('loading-placeholder');
    await tester.pumpWidget(
      const MaterialApp(
        home: OptimizedNetworkImage(
          url: 'https://example.invalid/cover.jpg',
          width: 40,
          height: 60,
          placeholder: SizedBox(key: placeholderKey),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final loading = image.loadingBuilder!(
      tester.element(find.byType(Image)),
      const SizedBox(),
      const ImageChunkEvent(cumulativeBytesLoaded: 1, expectedTotalBytes: 2),
    );

    await tester.pumpWidget(MaterialApp(home: loading));
    expect(find.byKey(placeholderKey), findsOneWidget);
  });

  testWidgets('el placeholder por defecto no agenda animaciones infinitas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClubBookCover(
          title: 'Portada lenta',
          imageUrl: 'https://example.invalid/slow.jpg',
          width: 40,
          height: 60,
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final loading = image.loadingBuilder!(
      tester.element(find.byType(Image)),
      const SizedBox(),
      const ImageChunkEvent(cumulativeBytesLoaded: 1, expectedTotalBytes: 2),
    );

    await tester.pumpWidget(MaterialApp(home: loading));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(await tester.pumpAndSettle(), 1);
  });

  testWidgets('un error de descarga usa el fallback configurado', (
    tester,
  ) async {
    const fallbackKey = Key('download-error');
    await tester.pumpWidget(
      const MaterialApp(
        home: OptimizedNetworkImage(
          url: 'https://example.invalid/avatar.jpg',
          width: 40,
          height: 40,
          fallback: SizedBox(key: fallbackKey),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final fallback = image.errorBuilder!(
      tester.element(find.byType(Image)),
      StateError('fallo simulado'),
      null,
    );

    await tester.pumpWidget(MaterialApp(home: fallback));
    expect(find.byKey(fallbackKey), findsOneWidget);
  });

  testWidgets('una portada válida conserva dimensiones y fit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClubBookCover(
          title: 'Portada',
          imageUrl: 'https://images.example.test/cover.jpg',
          width: 80,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 80);
    expect(image.height, 120);
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('dimensiona la caché de una miniatura según el DPR', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(devicePixelRatio: 3),
        child: OptimizedNetworkImage(
          url: 'https://example.test/thumb.jpg',
          width: 40,
          height: 60,
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as ResizeImage;
    expect(provider.width, 120);
    expect(provider.height, 180);
  });

  test('solo transforma URLs Cloudinary', () {
    expect(
      OptimizedNetworkImage.cloudinaryThumbnailUrl(
        'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        pixelWidth: 120,
        pixelHeight: 180,
      ),
      contains('/upload/f_auto,q_auto,w_120,h_180,c_fill/'),
    );
    expect(
      OptimizedNetworkImage.cloudinaryThumbnailUrl(
        'https://covers.example.com/sample.jpg',
        pixelWidth: 120,
      ),
      'https://covers.example.com/sample.jpg',
    );
  });
}
