typedef ChapterUserLoader = Future<String?> Function();
typedef ChapterAuxiliaryTask = Future<void> Function();
typedef ChapterUserTask = Future<void> Function(String user);

class ChapterInitialization {
  const ChapterInitialization._();

  static Future<void> run({
    required ChapterAuxiliaryTask loadComments,
    required ChapterUserLoader loadUser,
    required void Function(String? user) onUserLoaded,
    required ChapterAuxiliaryTask restoreDraft,
    required ChapterUserTask markSeen,
  }) async {
    // Debe ser la primera operación: cambia initialLoading de forma síncrona.
    final commentsRequest = loadComments();
    // La identidad puede resolverse en paralelo; solo las tareas que dependen
    // de ella esperan su resultado.
    final userRequest = loadUser();
    String? user;
    try {
      user = await userRequest;
    } catch (_) {
      // Los comentarios se autentican con Bearer y no dependen del nombre.
    }
    onUserLoaded(user);

    await Future.wait([
      commentsRequest,
      _ignoreFailure(restoreDraft),
      if (user != null && user.trim().isNotEmpty)
        _ignoreFailure(() => markSeen(user!)),
    ]);
  }

  static Future<void> _ignoreFailure(ChapterAuxiliaryTask operation) async {
    try {
      await operation();
    } catch (_) {
      // Son tareas auxiliares: nunca bloquean la conversación.
    }
  }
}
