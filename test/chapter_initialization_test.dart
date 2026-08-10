import 'dart:async';

import 'package:club_lectura_app/services/chapter_initialization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'inicia comentarios antes de esperar a la usuaria y solo una vez',
    () async {
      final comments = Completer<void>();
      final user = Completer<String?>();
      var commentCalls = 0;

      final initialization = ChapterInitialization.run(
        loadComments: () {
          commentCalls++;
          return comments.future;
        },
        loadUser: () => user.future,
        onUserLoaded: (_) {},
        restoreDraft: () async {},
        markSeen: (_) async {},
      );

      expect(commentCalls, 1);
      user.complete('Ada');
      comments.complete();
      await initialization;
      expect(commentCalls, 1);
    },
  );

  test('fallos de visto y borrador no bloquean los comentarios', () async {
    final comments = Completer<void>();
    var draftAttempted = false;
    var seenAttempted = false;
    var finished = false;
    final initialization = ChapterInitialization.run(
      loadComments: () async {
        await comments.future;
      },
      loadUser: () async => 'Ada',
      onUserLoaded: (_) {},
      restoreDraft: () async {
        draftAttempted = true;
        throw StateError('borrador');
      },
      markSeen: (_) async {
        seenAttempted = true;
        throw StateError('vista');
      },
    )..then((_) => finished = true);

    await Future<void>.delayed(Duration.zero);
    expect(draftAttempted, isTrue);
    expect(seenAttempted, isTrue);
    expect(finished, isFalse);

    comments.complete();
    await initialization;
    expect(finished, isTrue);
  });
}
