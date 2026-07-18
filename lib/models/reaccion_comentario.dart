enum ReaccionComentario {
  meGusta,
  pulgarArriba,
  deAcuerdo,
  meHaceReir,
  llorar,
  sorpresa,
  meEnfada,
  insultos,
  aplaudir,
}

extension ReaccionComentarioDatos on ReaccionComentario {
  String get apiValue => switch (this) {
    ReaccionComentario.meGusta => 'LIKE',
    ReaccionComentario.deAcuerdo => 'AGREE',
    ReaccionComentario.meEnfada => 'ANGRY',
    ReaccionComentario.meHaceReir => 'FUNNY',
    ReaccionComentario.pulgarArriba => 'THUMBS_UP',
    ReaccionComentario.llorar => 'CRY',
    ReaccionComentario.sorpresa => 'WOW',
    ReaccionComentario.insultos => 'SWEAR',
    ReaccionComentario.aplaudir => 'CLAP',
  };

  String get emoji => switch (this) {
    ReaccionComentario.meGusta => '❤️',
    ReaccionComentario.deAcuerdo => '💯',
    ReaccionComentario.meEnfada => '😡',
    ReaccionComentario.meHaceReir => '😂',
    ReaccionComentario.pulgarArriba => '👍',
    ReaccionComentario.llorar => '😢',
    ReaccionComentario.sorpresa => '😮',
    ReaccionComentario.insultos => '🤬',
    ReaccionComentario.aplaudir => '👏',
  };

  String get titulo => switch (this) {
    ReaccionComentario.meGusta => 'Me gusta',
    ReaccionComentario.deAcuerdo => '100% de acuerdo',
    ReaccionComentario.meEnfada => 'Me enfada',
    ReaccionComentario.meHaceReir => 'Me hace reír',
    ReaccionComentario.pulgarArriba => 'Me gusta',
    ReaccionComentario.llorar => 'Me entristece',
    ReaccionComentario.sorpresa => 'Me sorprende',
    ReaccionComentario.insultos => 'Me indigna',
    ReaccionComentario.aplaudir => 'Aplaudir',
  };

  static ReaccionComentario? fromApi(String? value) {
    for (final reaccion in ReaccionComentario.values) {
      if (reaccion.apiValue == value) return reaccion;
    }
    return null;
  }
}
