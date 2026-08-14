import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/onboarding_tutorial.dart';

class _HelpSection {
  const _HelpSection({
    required this.icono,
    required this.titulo,
    required this.items,
  });

  final String icono;
  final String titulo;
  final List<_HelpItem> items;
}

class _HelpItem {
  const _HelpItem({required this.pregunta, required this.respuesta});

  final String pregunta;
  final String respuesta;
}

const List<_HelpSection> _secciones = [
  _HelpSection(
    icono: '🔀',
    titulo: 'Modos de lectura',
    items: [
      _HelpItem(
        pregunta: '¿Qué modos de lectura tiene ClubReads?',
        respuesta:
            'ClubReads tiene dos modos:\n\n'
            '📖 Espacio lector personal — para quien quiere leer en solitario. '
            'Tienes tu biblioteca privada, racha lectora, mapa de calor anual '
            'y Wrapped (resumen del año). No necesitas unirte a ningún club.\n\n'
            '👥 Club lector — para leer en compañía. Incluye lecturas grupales, '
            'Clubvisión (votaciones), comentarios por capítulo, rankings, '
            'logros de club y más.',
      ),
      _HelpItem(
        pregunta: '¿Cómo elijo mi modo?',
        respuesta:
            'Al iniciar sesión por primera vez, la app te pregunta cómo '
            'quieres empezar. Puedes elegir "Mi espacio lector" para modo '
            'personal, o "Crear un club" / "Tengo un código" para modo club.\n\n'
            'Si ya tienes una cuenta, puedes crear tu espacio personal desde '
            '"Mis clubes" en cualquier momento, o unirte a un club con un código '
            'de invitación.',
      ),
      _HelpItem(
        pregunta: '¿Puedo cambiar de modo o tener los dos?',
        respuesta:
            'Sí. Puedes tener tanto tu espacio personal como uno o más clubes. '
            'Desde "Mis clubes" verás todos y podrás cambiar entre ellos. '
            'La pestaña activa cambia según el modo seleccionado.',
      ),
      _HelpItem(
        pregunta: '¿Qué es "Mi espacio lector"?',
        respuesta:
            'Es una pantalla exclusiva del modo personal que muestra:\n\n'
            '• Tus estadísticas (libros leídos, páginas, mes actual, racha)\n'
            '• Logros desbloqueados y progreso hacia los siguientes\n'
            '• Check-in lector diario con racha de días\n'
            '• Mapa de calor anual con tu actividad\n'
            '• Acceso a tu Wrapped del año\n\n'
            'En modo club, estas mismas funcionalidades están en tu Perfil → '
            'sección "Seguimiento lector".',
      ),
    ],
  ),
  _HelpSection(
    icono: '🏛️',
    titulo: 'Clubes',
    items: [
      _HelpItem(
        pregunta: '¿Cómo creo un club?',
        respuesta:
            'En "Mis clubes" pulsa el botón "Crear club". Escribe un nombre '
            'y una descripción. Al crearlo serás la administradora y podrás '
            'invitar a más personas con el código que te genera la app.',
      ),
      _HelpItem(
        pregunta: '¿Cómo invito a alguien a mi club?',
        respuesta:
            'Entra en "Mis clubes", pulsa el icono de invitación del club '
            'que administras y comparte el código que aparece. '
            'Quien lo reciba puede unirse desde la misma pantalla pulsando '
            '"Entrar con invitación" e introduciendo el código.',
      ),
      _HelpItem(
        pregunta: '¿Puedo pertenecer a varios clubes?',
        respuesta:
            'Sí. Puedes estar en tantos clubes como quieras, aunque solo '
            'uno estará activo a la vez. Cambia el activo desde "Mis clubes".',
      ),
      _HelpItem(
        pregunta: '¿Cómo edito el club o añado una foto?',
        respuesta:
            'En "Mis clubes" pulsa el icono de ajustes ⚙️ del club. '
            'Desde ahí puedes editar el nombre y la descripción, y cambiar la foto '
            'del club desde la galería o con una URL. '
            'Solo la propietaria y las administradoras pueden editar el club.',
      ),
      _HelpItem(
        pregunta: '¿Cómo veo quién está en el club?',
        respuesta:
            'En los ajustes del club encontrarás la opción "Miembros", '
            'que muestra a todas las personas del club con su rol. '
            'El número de miembros también aparece en el propio menú.',
      ),
      _HelpItem(
        pregunta: '¿Puedo salir de un club?',
        respuesta:
            'Sí, desde los ajustes del club verás la opción "Salir del club". '
            'Perderás acceso a las lecturas y conversaciones de ese club. '
            'La propietaria no puede salir — tendría que transferir la propiedad primero.',
      ),
      _HelpItem(
        pregunta: '¿Qué diferencia hay entre administradora y miembro?',
        respuesta:
            'La administradora puede abrir y cerrar votaciones de Clubvisión, '
            'gestionar la lectura activa del club y obtener el código de invitación. '
            'Los miembros pueden votar, comentar y proponer libros según las '
            'reglas de cada sección.',
      ),
    ],
  ),
  _HelpSection(
    icono: '📖',
    titulo: 'Libros',
    items: [
      _HelpItem(
        pregunta: '¿Cómo añado un libro?',
        respuesta:
            'Hay dos formas. La primera: en la pestaña "Libros" pulsa el botón + '
            'y rellena los datos manualmente (título, autor, género, saga, formato '
            'y prioridad). La segunda: explora la biblioteca global desde "Mi universo '
            'lector" → "Explorar la biblioteca", busca el libro y añádelo desde ahí '
            'sin tener que introducir los datos a mano.',
      ),
      _HelpItem(
        pregunta: '¿Qué significa "autoconclusivo"?',
        respuesta:
            'Un libro autoconclusivo no pertenece a ninguna saga: tiene '
            'principio y fin en sí mismo. Si desmarcas esta opción, '
            'tendrás que indicar el nombre de la saga y el número de tomo.',
      ),
      _HelpItem(
        pregunta: '¿Cómo marco un libro como terminado?',
        respuesta:
            'Abre el detalle del libro y cambia su estado a "Historia terminada" '
            'en el selector de estado. Podrás añadir tu valoración, '
            'las fechas de lectura y una reseña personal.',
      ),
      _HelpItem(
        pregunta: '¿Qué estados puede tener un libro?',
        respuesta:
            '"En mi estantería" (pendiente), "Leyendo" (en curso), '
            '"Necesito un respiro" (pausado), "Otra vuelta" (relectura), '
            '"No era para mí" (abandonado) e "Historia terminada" (finalizado). '
            'Puedes cambiar el estado en cualquier momento desde la ficha del libro.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la biblioteca global?',
        respuesta:
            'Es el catálogo compartido de todos los libros que existen en ClubReads. '
            'Puedes explorarla desde "Mi universo lector" usando el icono de búsqueda. '
            'Desde ahí puedes añadir cualquier libro directamente a tu biblioteca '
            'personal sin introducir los datos manualmente.',
      ),
      _HelpItem(
        pregunta: '¿Cómo marco un libro como favorito?',
        respuesta:
            'Desde la ficha de cualquier libro de tu biblioteca verás un icono '
            'de corazón ♥. Púlsalo para marcarlo como favorito.\n\n'
            'Puedes tener hasta 5 libros favoritos. La app te avisará cuando '
            'llegues al límite. Tus favoritos aparecen en la tarjeta '
            '"Favoritos del club" del dashboard, donde tus compañeras pueden '
            'ver qué libros son tus preferidos.',
      ),
      _HelpItem(
        pregunta: '¿Puedo ir al detalle de un libro que acabo de añadir desde el catálogo?',
        respuesta:
            'Sí. Justo después de añadir un libro desde la biblioteca global, '
            'aparece un botón "Ver en mi biblioteca" en la pantalla de confirmación. '
            'Púlsalo para ir directamente a la ficha del libro con todos sus datos: '
            'estado, valoración, fechas y más.',
      ),
    ],
  ),
  _HelpSection(
    icono: '📥',
    titulo: 'Importaciones',
    items: [
      _HelpItem(
        pregunta: '¿Cómo importo desde Bookmory o Goodreads?',
        respuesta:
            'Ve a Perfil → Más y elige "Importar desde Bookmory" o '
            '"Importar desde Goodreads". Para Bookmory selecciona el archivo '
            '.xlsx exportado directamente por la aplicación; para Goodreads, '
            'su archivo .csv. ClubReads revisará el contenido antes de guardar '
            'nada y te permitirá confirmar los libros seleccionados.',
      ),
      _HelpItem(
        pregunta: '¿Qué libros se importan?',
        respuesta:
            'Solo se importan los libros terminados que tengan valoración. '
            'Los pendientes, los que estás leyendo y los terminados sin valorar '
            'se omiten. Si falta la fecha de finalización, ClubReads asigna una '
            'fecha segura para poder conservar el libro en tu historial.',
      ),
      _HelpItem(
        pregunta: '¿Qué significan "Nuevos" y "Para añadir"?',
        respuesta:
            '"Nuevos" son libros que todavía no existen en el catálogo: se '
            'crearán y se añadirán a tu biblioteca. "Para añadir" ya existen '
            'en ClubReads, pero no están en tu biblioteca: se reutilizará su '
            'ficha. Ambos aparecen seleccionados automáticamente; puedes '
            'desmarcar cualquier libro que no quieras importar.',
      ),
      _HelpItem(
        pregunta: '¿Qué significa "Protegidos"?',
        respuesta:
            'Son libros que ya tienes en ClubReads. No tienes que hacer nada: '
            'la importación no sustituirá tus estados, fechas, valoraciones, '
            'reseñas, prioridades, formatos, sagas ni historial guardado. Por '
            'eso no se incluyen entre los libros seleccionados para importar.',
      ),
      _HelpItem(
        pregunta: '¿Qué hago con los libros "Para revisar"?',
        respuesta:
            'ClubReads ha encontrado varias coincidencias posibles y no puede '
            'decidir con seguridad cuál es la correcta. Esos libros no se '
            'importan automáticamente. Termina primero la importación y después '
            'búscalos en la biblioteca global para añadir la ficha correcta. '
            'Si ninguna coincide, puedes crear el libro manualmente.',
      ),
      _HelpItem(
        pregunta: '¿Qué significa "Pendientes o sin valorar"?',
        respuesta:
            'Son filas que no cumplen las condiciones de importación, que no '
            'tienen título o autor, o que están repetidas dentro del archivo. '
            'Se omiten y no modifican tu biblioteca.',
      ),
      _HelpItem(
        pregunta: '¿Qué hago si una importación grande da error?',
        respuesta:
            'Puedes volver a seleccionar el mismo archivo sin perder lo ya '
            'guardado. Si hay muchos libros, pulsa "Ninguno", selecciona grupos '
            'de unos 20 o 30 e impórtalos por tandas. Al abrir de nuevo el archivo, '
            'los libros ya incorporados aparecerán como protegidos.',
      ),
    ],
  ),
  _HelpSection(
    icono: '🗂️',
    titulo: 'Sagas',
    items: [
      _HelpItem(
        pregunta: '¿Cómo aparecen mis sagas?',
        respuesta:
            'Automáticamente. Cuando añades libros que pertenecen a la '
            'misma saga, la app los agrupa en la pestaña "Sagas". '
            'Verás el progreso de cada saga, cuántos tomos has leído '
            'y cuál es el siguiente para continuar.',
      ),
      _HelpItem(
        pregunta: '¿Qué significan los iconos en las portadas?',
        respuesta:
            'Cada portada lleva un indicador de estado en la esquina inferior: '
            '✅ morado = terminado, 📖 azul = leyendo, 🔖 naranja = pendiente. '
            'Los tomos sin marca no están aún en tu biblioteca. '
            'El candadito 🔒 indica un tomo bloqueado o no añadido.',
      ),
      _HelpItem(
        pregunta: '¿Qué es "Completar saga"?',
        respuesta:
            'Es una herramienta para buscar los volúmenes que faltan en el '
            'catálogo global. Entra en una saga, pulsa "Completar saga", busca '
            'el libro y confirma que pertenece a ella antes de añadirlo.',
      ),
      _HelpItem(
        pregunta: '¿Qué tengo que indicar al completar una saga?',
        respuesta:
            'Depende de si el libro ya está en tu biblioteca:\n\n'
            '• Si ya lo tienes terminado: solo necesitas indicar el número '
            'de tomo. Tus fechas, valoración y reseña se conservan intactas.\n\n'
            '• Si está en tu biblioteca pero no terminado: puedes ajustar '
            'el estado respetando tus datos actuales.\n\n'
            '• Si es un libro nuevo: indica el número de tomo, estado, '
            'formato y, si está terminado, las fechas y valoración.',
      ),
      _HelpItem(
        pregunta: '¿Se añade también a mi biblioteca?',
        respuesta:
            'Sí. Al confirmar, el volumen se vincula a la saga y se añade a '
            'tu biblioteca con el estado y formato elegidos, todo en una sola '
            'operación. La biblioteca se actualiza automáticamente.',
      ),
      _HelpItem(
        pregunta: '¿Puedo reordenar los tomos de una saga?',
        respuesta:
            'Sí. En la card de cada saga verás el icono ⇅ si tienes al menos '
            '2 volúmenes. Al pulsarlo, los tomos se convierten en una lista '
            'arrastrable: arrastra y suelta para cambiar el orden visual. '
            'Este orden es tuyo personal — no afecta a otras lectoras, '
            'ni a tus fechas ni valoraciones. Pulsa "Guardar orden" para '
            'confirmar o la X para cancelar sin cambios.',
      ),
      _HelpItem(
        pregunta: '¿Y si un tomo no está en ClubReads o no quiero leerlo?',
        respuesta:
            'Desde el hueco correspondiente de la saga puedes marcarlo como '
            '"Leído fuera de ClubReads" u "Omitido". Si más adelante añades '
            'el volumen real con "Completar saga", esa marca se elimina '
            'automáticamente.',
      ),
      _HelpItem(
        pregunta: '¿Qué significa que una saga esté "abandonada"?',
        respuesta:
            'Si marcas algún libro de la saga como "No era para mí" (abandonado), '
            'la saga completa pasa automáticamente al estado Abandonada. '
            'En la pestaña "Sagas" aparece un filtro específico para verlas. '
            'Siempre puedes retomarla cambiando el estado del libro.',
      ),
      _HelpItem(
        pregunta: '¿Puedo ocultar o eliminar una saga?',
        respuesta:
            'Sí, desde la card de cada saga tienes dos opciones:\n\n'
            '👁️ Ocultar — la saga desaparece de tu lista pero puedes '
            'recuperarla desde Perfil → Sagas ocultas. Útil si no quieres '
            'verla pero podrías retomarla en el futuro.\n\n'
            '🗑️ Eliminar — la saga desaparece de tu lista de forma permanente '
            'hasta que la recuperes desde Perfil → Sagas ocultas. '
            'Importante: tus libros, lecturas, fechas, valoraciones y reseñas '
            'se conservan intactos en tu biblioteca. Solo desaparece '
            'la agrupación visual de la saga.',
      ),
    ],
  ),
  _HelpSection(
    icono: '🗳️',
    titulo: 'Clubvisión',
    items: [
      _HelpItem(
        pregunta: '¿Qué es Clubvisión?',
        respuesta:
            'Es el sistema de votación del club para elegir el próximo libro '
            'de lectura grupal. Funciona por ediciones mensuales: se abre una '
            'votación, las miembros votan entre las candidatas y la ganadora '
            'se convierte en la siguiente lectura del club.',
      ),
      _HelpItem(
        pregunta: '¿Cómo se eligen las candidatas?',
        respuesta:
            'Las candidatas se generan automáticamente. Para que un libro '
            'aparezca como candidata tiene que cumplir tres condiciones: '
            'que al menos 2 miembros del club lo tengan en su biblioteca personal, '
            'que no haya sido ya leído por el club, y que no haya ganado '
            'una edición anterior de Clubvisión.',
      ),
      _HelpItem(
        pregunta: '¿Qué pasa si no hay candidatas?',
        respuesta:
            'Si ningún libro cumple las condiciones, Clubvisión no se abre '
            'ese mes y verás un aviso en la pantalla del club explicando '
            'el motivo. Para que haya candidatas, al menos dos miembros '
            'tienen que tener el mismo libro en "En mi estantería".',
      ),
      _HelpItem(
        pregunta: '¿Cómo voto?',
        respuesta:
            'Cuando la votación está abierta, entra en Clubvisión '
            'y ordena las candidatas según tus preferencias arrastrándolas. '
            'Tu voto se guarda al confirmar. Solo puedes votar una vez por edición.',
      ),
      _HelpItem(
        pregunta: '¿Puedo ver cómo ha votado cada persona?',
        respuesta:
            'Sí, pero solo una vez cerrada la votación. Cuando se cierra '
            'la edición, cualquier miembro puede ver el desglose completo '
            'de votos en "Cómo votaron". '
            'Durante la votación activa, los votos son privados.',
      ),
      _HelpItem(
        pregunta: '¿Quién abre y cierra la votación?',
        respuesta:
            'Solo la administradora del club puede abrir y cerrar cada edición '
            'de Clubvisión. El resto de miembros solo pueden votar mientras '
            'la votación esté abierta.',
      ),
    ],
  ),
  _HelpSection(
    icono: '📚',
    titulo: 'Lecturas y citas',
    items: [
      _HelpItem(
        pregunta: '¿Cómo sigo la lectura activa del club?',
        respuesta:
            'En la pestaña "Lecturas" encontrarás el libro actual del club '
            'dividido por capítulos. Pulsa en un capítulo para leer los '
            'comentarios de las demás miembros y añadir el tuyo.',
      ),
      _HelpItem(
        pregunta: '¿Cómo comento en un capítulo?',
        respuesta:
            'Entra en la lectura activa, selecciona el capítulo '
            'y pulsa el campo de comentario al final. '
            'Puedes responder a comentarios de otras miembros '
            'y reaccionar con emojis.',
      ),
      _HelpItem(
        pregunta: '¿Puedo reaccionar a las respuestas de un comentario?',
        respuesta:
            'Sí. Las respuestas tienen el mismo selector completo de reacciones '
            'que los comentarios principales: pulsa el botón de emoji en la '
            'respuesta para elegir tu reacción. También puedes cambiarla '
            'o quitarla pulsando de nuevo.',
      ),
      _HelpItem(
        pregunta: '¿Qué son las citas?',
        respuesta:
            'Las citas son frases o fragmentos que destacas mientras lees. '
            'Puedes guardarlas en la sección "Citas" para no perderlas '
            'y compartirlas con el club. Son tu cuaderno de frases favoritas.',
      ),
      _HelpItem(
        pregunta: '¿Qué es el Kit de lectura?',
        respuesta:
            'El Kit de lectura es una selección de recursos para preparar '
            'la experiencia: playlist musical, paleta de colores, atmósfera '
            'y story para compartir. Lo encontrarás en la ficha de cada libro.',
      ),
    ],
  ),
  _HelpSection(
    icono: '🏆',
    titulo: 'Logros',
    items: [
      _HelpItem(
        pregunta: '¿Qué son los logros?',
        respuesta:
            'Son medallas que desbloqueas automáticamente al alcanzar hitos '
            'en tu lectura y participación en el club. Hay logros de distintas '
            'rarezas: Común, Raro, Épico y Legendario. Se resetean cada año — '
            'solo cuentan los libros, reseñas y participación del año en curso.\n\n'
            'Puedes verlos desde "Mi universo lector" → "Ver todos" o '
            'desde tu perfil lector → sección Logros.',
      ),
      _HelpItem(
        pregunta: '📚 Categoría Lectora — ¿cómo se desbloquea?',
        respuesta:
            'Estos logros se consiguen terminando libros:\n\n'
            '📖 Primer libro — completa 1 lectura\n'
            '📚 Lectora en marcha — llega a 5 libros terminados\n'
            '🔟 Lectora habitual — alcanza 10 libros finalizados\n'
            '🌟 Voraz lectora (Raro) — 25 libros en tu historial\n'
            '🏆 Biblióvora (Épico) — 50 libros completados\n'
            '💯 Centenaria lectora (Legendario) — 100 libros. Una hazaña.',
      ),
      _HelpItem(
        pregunta: '📄 Categoría Páginas — ¿cómo se desbloquea?',
        respuesta:
            'Se calculan sumando las páginas de todos tus libros terminados:\n\n'
            '📄 Mil páginas — supera las 1.000 páginas leídas\n'
            '📃 Lectora resistente (Raro) — 5.000 páginas\n'
            '📜 Maratoniana de páginas (Épico) — 10.000 páginas\n'
            '🗺️ Leyenda de las páginas (Legendario) — 50.000 páginas',
      ),
      _HelpItem(
        pregunta: '🌀 Categoría Sagas — ¿cómo se desbloquea?',
        respuesta:
            'Se desbloquean al completar sagas enteras (todos los volúmenes terminados '
            'y la saga marcada como finalizada por la editorial):\n\n'
            '🌀 Saga completada (Raro) — termina tu primera saga\n'
            '💫 Maestra de sagas (Épico) — completa 3 sagas\n'
            '🌌 Coleccionista de sagas (Legendario) — 5 sagas completas',
      ),
      _HelpItem(
        pregunta: '🎭 Categoría Géneros — ¿cómo se desbloquea?',
        respuesta:
            'Se obtienen leyendo libros de géneros específicos:\n\n'
            '💗 Romance addict (Raro) — 10 libros de Romance\n'
            '🧙 Guardiana de mundos (Raro) — 10 libros de Fantasía\n'
            '🔪 Thriller queen (Raro) — 5 libros de Thriller\n'
            '🖤 Dark side (Raro) — 5 libros de Dark Romance\n'
            '🗺️ Exploradora (Épico) — lee libros de 5 géneros distintos',
      ),
      _HelpItem(
        pregunta: '✍️ Categoría Reseñas — ¿cómo se desbloquea?',
        respuesta:
            'Se consiguen escribiendo reseñas en tus libros terminados:\n\n'
            '✍️ Primera reseña — escribe tu primera reseña\n'
            '📝 Crítica literaria (Raro) — 10 reseñas escritas\n'
            '🖊️ Pluma incansable (Épico) — 25 reseñas en tu historial',
      ),
      _HelpItem(
        pregunta: '💬 Categoría Club — ¿cómo se desbloquea?',
        respuesta:
            'Se obtienen participando en las lecturas del club:\n\n'
            '💬 Primera voz — comenta por primera vez en una lectura\n'
            '🗣️ Voz del club (Raro) — 10 comentarios en lecturas\n'
            '🎤 Alma del club (Épico) — 50 comentarios. La más activa.',
      ),
      _HelpItem(
        pregunta: '🗳️ Categoría Clubvisión — ¿cómo se desbloquea?',
        respuesta:
            'Se consiguen votando en las ediciones de Clubvisión:\n\n'
            '🗳️ Primera votante — participa en tu primera Clubvisión\n'
            '🏛️ Votante fiel (Raro) — 5 participaciones en Clubvisión\n'
            '👑 Electora veterana (Épico) — 10 votaciones en Clubvisión',
      ),
      _HelpItem(
        pregunta: '🔥 Categoría Constancia — ¿cómo se desbloquea?',
        respuesta:
            'Premian la intensidad lectora en períodos cortos:\n\n'
            '🔥 Mes intenso (Raro) — 5 libros en un mismo mes\n'
            '⚡ Maratoniana (Épico) — 10 libros en un mes\n'
            '🗓️ Gran año lector (Raro) — 50 libros en un año\n'
            '🏅 Año legendario (Legendario) — 100 libros en un solo año',
      ),
      _HelpItem(
        pregunta: '¿Qué es el Reto lector del club?',
        respuesta:
            'En "El Club" → "Reto lector" cada lectora puede marcarse un '
            'objetivo personal de libros para el año en curso. '
            'El progreso se actualiza automáticamente según vas finalizando libros.\n\n'
            'Puedes ver el avance de todas las compañeras ordenado por porcentaje '
            'de cumplimiento. Las que han superado su reto aparecen con 🏆.\n\n'
            'Además existe un reto colectivo: la suma de todos los objetivos '
            'individuales del club. Si entre todas lo superáis, '
            'se celebra con un logro especial.\n\n'
            'Para crear o cambiar tu reto, entra en "Reto lector" y pulsa '
            '"Crear reto" o "Cambiar". Puedes modificarlo en cualquier momento.',
      ),
    ],
  ),
  _HelpSection(
    icono: '🔥',
    titulo: 'Check-in, mapa de calor y Wrapped',
    items: [
      _HelpItem(
        pregunta: '¿Qué es el check-in lector diario?',
        respuesta:
            'Es un botón para marcar que has leído hoy. Cada vez que lo pulsas, '
            'se suma un día a tu racha lectora. Si olvidas hacerlo un día, '
            'la racha se mantiene si el día anterior ya lo registraste.\n\n'
            'Lo encontrarás en:\n'
            '• Modo personal → pestaña "Mi espacio"\n'
            '• Cualquier modo → tu Perfil → sección "Seguimiento lector"',
      ),
      _HelpItem(
        pregunta: '¿Cómo funciona la racha lectora?',
        respuesta:
            'La racha cuenta los días consecutivos en los que has hecho '
            'check-in. Si hoy ya lo hiciste, o si ayer lo hiciste y hoy '
            'aún no has tenido tiempo, la racha se mantiene. '
            'Si no hay actividad ni de ayer ni de hoy, la racha vuelve a 0.\n\n'
            'La racha aparece en el banner de "Mi espacio" y junto al '
            'botón de check-in.',
      ),
      _HelpItem(
        pregunta: '¿Qué es el mapa de calor anual?',
        respuesta:
            'Es un calendario visual estilo GitHub que muestra tu actividad '
            'lectora durante el año: cada cuadrado representa un día y su '
            'color indica el nivel de actividad (del gris al verde oscuro).\n\n'
            'El mapa combina tres fuentes:\n'
            '• Check-ins explícitos que tú marcas\n'
            '• Días en los que actualizaste el progreso de algún libro\n'
            '• Días en los que terminaste un libro (cuentan el doble)\n\n'
            'Haz scroll horizontal para ver todo el año. Toca cualquier '
            'cuadrado para ver la fecha y el nivel de actividad.',
      ),
      _HelpItem(
        pregunta: '¿Qué es el Wrapped anual?',
        respuesta:
            'Es un resumen de tu año lector al estilo Spotify Wrapped. '
            'Se presenta en diapositivas deslizables con:\n\n'
            '• Total de libros y páginas leídas\n'
            '• Tu racha y días activos\n'
            '• Género y autor favoritos\n'
            '• Mejor mes del año y gráfico mensual\n'
            '• Valoración media de tus lecturas\n'
            '• El libro más largo que terminaste\n'
            '• El primer libro del año\n'
            '• Comparativa con el año anterior\n\n'
            'Toca a la derecha para avanzar y a la izquierda para retroceder.',
      ),
      _HelpItem(
        pregunta: '¿Están disponibles en modo club también?',
        respuesta:
            'Sí. El check-in, el mapa de calor y el Wrapped son funcionalidades '
            'personales: aparecen en tu Perfil → sección "Seguimiento lector" '
            'independientemente de si estás en modo club o personal.\n\n'
            'En modo lector personal también aparecen en la pestaña "Mi espacio".',
      ),
    ],
  ),
  _HelpSection(
    icono: '🌈',
    titulo: 'Atmósferas y personalización',
    items: [
      _HelpItem(
        pregunta: '¿Qué son las atmósferas?',
        respuesta:
            'Son temas visuales que cambian los colores y el ambiente de '
            'la app según el libro que está leyendo el club. La administradora '
            'puede activar una atmósfera para toda la comunidad desde '
            'la sección Atmósferas dentro de la lectura activa.',
      ),
      _HelpItem(
        pregunta: '¿Cómo cambio mi avatar?',
        respuesta:
            'Ve a tu perfil y pulsa sobre tu avatar. Podrás elegir '
            'un color y un icono, o subir una foto desde tu galería.',
      ),
      _HelpItem(
        pregunta: '¿Puedo personalizar mi perfil?',
        respuesta:
            'Sí. En tu perfil puedes editar tu avatar, ver tus estadísticas '
            'lectoras, tu timeline de lecturas, los géneros favoritos, '
            'los meses lectores y todos los libros que has terminado o abandonado.',
      ),
    ],
  ),
  _HelpSection(
    icono: '📊',
    titulo: 'Estadísticas y perfil',
    items: [
      _HelpItem(
        pregunta: '¿Qué muestra "Mi universo lector"?',
        respuesta:
            'Es tu pantalla principal con un resumen de todo: libros que estás '
            'leyendo, sagas en curso, la estantería del mes, tu calendario '
            'de lectura, las tendencias de la comunidad y el acceso a tus clubes.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la estantería del mes?',
        respuesta:
            'Una representación visual en forma de librería de madera con todos '
            'los libros que has terminado durante el mes actual. Los libros '
            'caen y se colocan animados cada vez que entras en la pantalla. '
            'Si el libro tiene valoración, aparece una estrella sobre la portada.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la biblioteca anual?',
        respuesta:
            'La estantería con todos los libros que has terminado en '
            'el año en curso. La encontrarás en tu perfil lector, '
            'en la sección Resumen. También se anima al entrar.',
      ),
      _HelpItem(
        pregunta: '¿Qué son las secciones del perfil?',
        respuesta:
            '"Resumen" muestra tus métricas, la biblioteca anual y tus géneros favoritos.\n\n'
            '"Timeline" muestra tu historial de lecturas ordenado por fecha.\n\n'
            '"Finalizados" lista todos los libros terminados y abandonados '
            'agrupados por año.\n\n'
            '"Meses lectores" muestra un calendario por cada mes en el que has '
            'leído algún libro, con las portadas colocadas en los días que las terminaste.\n\n'
            '"Logros" muestra todas tus medallas agrupadas por categoría, '
            'con barra de progreso y estado de desbloqueo.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la tarjeta "Favoritos del club"?',
        respuesta:
            'Es una tarjeta del dashboard (modo club) que muestra los 5 libros '
            'favoritos de cada miembro de tu club.\n\n'
            'Verás el avatar de cada compañera con las portadas de sus favoritos '
            'encima. La tarjeta te muestra primero a "Tú" con tus propios favoritos, '
            'y luego al resto de miembros que tengan al menos uno marcado.\n\n'
            'Pulsa sobre el avatar de cualquier miembro para ver su lista completa '
            'de favoritos con título, autora y género.\n\n'
            'Para que aparezca necesitas tener al menos un libro marcado como '
            'favorito ♥ en tu biblioteca.',
      ),
      _HelpItem(
        pregunta: '¿Cómo funcionan las notificaciones?',
        respuesta:
            'Recibirás notificaciones dentro de la app (campanita en el dashboard) '
            'cuando ocurra algo relevante en tu club: nueva lectura oficial, '
            'nueva miembro, resultado de Clubvisión, nuevo libro en la biblioteca '
            'o cuando alguien comenta en una lectura en la que participas.',
      ),
      _HelpItem(
        pregunta: '¿Qué es "Seguimiento lector" en el perfil?',
        respuesta:
            'Es la sección de tu perfil (solo visible en tu propio perfil) '
            'que agrupa el check-in diario, el mapa de calor anual y el '
            'botón para ver tu Wrapped. Disponible en modo club y personal.',
      ),
    ],
  ),
];

// ─────────────────────────────────────────────
// Página de Ayuda
// ─────────────────────────────────────────────

class AyudaPage extends StatelessWidget {
  const AyudaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda'),
        actions: [
          IconButton(
            tooltip: 'Ver tutorial de inicio',
            icon: const Icon(Icons.play_circle_outline_rounded),
            onPressed: () => mostrarOnboardingTutorial(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        children: [
          // ── Cabecera ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 28)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿En qué te podemos ayudar?',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 15,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Aquí encontrarás explicaciones de todas las partes de ClubReads.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Botón para relanzar tutorial ──
          ClubCard(
            elevated: false,
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Ver tutorial de bienvenida',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Repasa los conceptos clave de la app'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => mostrarOnboardingTutorial(context),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          ..._secciones.map((seccion) => _SeccionAyuda(seccion: seccion)),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sección expandible
// ─────────────────────────────────────────────

class _SeccionAyuda extends StatelessWidget {
  const _SeccionAyuda({required this.seccion});

  final _HelpSection seccion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClubCard(
        elevated: false,
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  seccion.icono,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Text(
              seccion.titulo,
              style: AppTextStyles.title.copyWith(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textMuted,
            children: seccion.items
                .map((item) => _PreguntaRespuesta(item: item))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pregunta / respuesta
// ─────────────────────────────────────────────

class _PreguntaRespuesta extends StatelessWidget {
  const _PreguntaRespuesta({required this.item});

  final _HelpItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textMuted,
            title: Text(
              item.pregunta,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            children: [
              Text(
                item.respuesta,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
