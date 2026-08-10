import 'package:club_lectura_app/services/comment_publication.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'un error de publicación conserva borrador y no inserta tarjeta',
    () async {
      var draftCleared = false;
      var inserted = false;

      await expectLater(
        publishConfirmedComment<String>(
          publish: () async => throw StateError('fallo POST'),
          onConfirmed: (_) => inserted = true,
          clearDraft: () async => draftCleared = true,
        ),
        throwsStateError,
      );

      expect(inserted, isFalse);
      expect(draftCleared, isFalse);
    },
  );

  test('solo confirma y limpia después de recibir el comentario', () async {
    final events = <String>[];

    final result = await publishConfirmedComment<String>(
      publish: () async {
        events.add('server');
        return 'comment-new';
      },
      onConfirmed: (value) => events.add('insert:$value'),
      clearDraft: () async => events.add('clear'),
    );

    expect(result, 'comment-new');
    expect(events, ['server', 'insert:comment-new', 'clear']);
  });
}
