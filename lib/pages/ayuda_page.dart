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
            'ClubReads puede usarse de dos formas:\n\n'
            '📖 Espacio lector personal — para quien quiere leer en solitario. '
            'Tienes tu biblioteca privada, racha de lectura, mapa de calor anual '
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
        pregunta: '¿Cómo creo mi espacio personal si ya pertenezco a un club?',
        respuesta:
            'Si ya tienes una cuenta de club y quieres añadir tu espacio lector '
            'personal, ve a "Mis clubes" y pulsa el botón "Crear mi espacio '
            'personal" que aparece al final de la lista (solo visible si aún '
            'no tienes uno).\n\n'
            'Tu espacio personal hereda toda tu biblioteca individual: libros, '
            'historial, valoraciones, sagas, favoritos y estadísticas. '
            'Es completamente independiente del club y solo tú puedes verlo.',
      ),
      _HelpItem(
        pregunta: '¿Qué es "Mi espacio lector"?',
        respuesta:
            'Es una pantalla exclusiva del modo personal que muestra:\n\n'
            '• Tus estadísticas (libros leídos, páginas, mes actual, racha)\n'
            '• Logros desbloqueados y progreso hacia los siguientes\n'
            '• Check-in lector diario con racha de días\n'
            '• Mapa de calor anual con tu actividad\n'
            '• Acceso a tu Perfil lector\n\n'
            'El Perfil mantiene la misma estructura tengas o no clubes. En Resumen '
            'encontrarás el seguimiento de lectura; Wrapped está en Favoritos.',
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
            'y una descripción. Al crearlo tendrás permisos de administración y podrás '
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
            'Solo quien creó el club y sus administradores pueden editarlo.',
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
            'Quien tenga la propiedad no puede salir: antes debe transferirla.',
      ),
      _HelpItem(
        pregunta: '¿Qué diferencia hay entre administrador y miembro?',
        respuesta:
            'Quien administra el club puede abrir y cerrar votaciones de Clubvisión, '
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
            'Puedes explorar el catálogo compartido desde "Mi universo lector" → '
            '"Explorar la biblioteca" y añadir una ficha existente a tu biblioteca personal.\n\n'
            'Para crear una ficha manualmente, pulsa "Añadir libro" en "Últimas '
            'incorporaciones" del dashboard global. Si estás dentro de un club, '
            'también puedes usar el botón + de la pestaña "Libros"; ambos accesos '
            'abren el mismo formulario.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la lista de deseos?',
        respuesta:
            'La lista de deseos te permite guardar libros de "Novedades" o '
            '"Próximos lanzamientos" que te interesan antes de decidirte a añadirlos '
            'a tu biblioteca.\n\n'
            'Pulsa el icono de carrito 🛒 en la esquina superior de cualquier portada '
            'en esas secciones para añadirlo o quitarlo. Cuando un libro está en tu '
            'lista, la portada muestra un badge naranja que te lo confirma.',
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
        pregunta: '¿Qué pasa cuando termino un libro?',
        respuesta:
            'Al marcar un libro como "Historia terminada" se abre un panel '
            'para guardar tu valoración (1–5 estrellas), las fechas de lectura '
            'y una reseña personal opcional.\n\n'
            '🎉 Una vez guardado, la app muestra una pequeña celebración con '
            'confeti. El libro aparece inmediatamente en tu historial, en la '
            'estantería del mes y cuenta para el reto lector si tienes uno activo.',
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
        pregunta: '¿Cómo funcionan las relecturas y el progreso?',
        respuesta:
            'Desde la ficha de un libro terminado puedes iniciar “Otra vuelta”. '
            'La relectura tiene sus propias fechas y progreso, sin sobrescribir la '
            'lectura original. Puedes introducir o corregir la página actual, incluso '
            'a una cifra menor. Al terminar, la relectura aparece como un registro '
            'propio en Historial, en el calendario mensual y entre las opciones de '
            'Libro del año del mes correspondiente.',
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
            'Puedes tener hasta 5. En tu Perfil → Favoritos también puedes añadirlos '
            'desde los huecos disponibles. Al pulsar una portada puedes quitarla o '
            'sustituirla conservando su posición. En perfiles ajenos solo se consultan.\n\n'
            'Si perteneces a un club, la tarjeta "Favoritos del club" permite ver '
            'los favoritos compartidos por sus miembros.',
      ),
      _HelpItem(
        pregunta:
            '¿Puedo ver la ficha de un libro que aparece en el panel pero no tengo en mi biblioteca?',
        respuesta:
            'Sí. Mantén pulsado cualquier portada del panel (secciones "Últimas '
            'incorporaciones" o "Se está leyendo mucho") y elige "Ver ficha completa". '
            'Se abrirá la ficha detallada del libro con su Kit de lectura, enlace a '
            'Goodreads y estadísticas del club, aunque todavía no lo hayas añadido '
            'a tu biblioteca.',
      ),
      _HelpItem(
        pregunta:
            '¿Puedo ir al detalle de un libro que acabo de añadir desde el catálogo?',
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
            'Este orden es personal: no afecta a otros lectores, '
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
            'recuperarla desde Perfil → Más → Sagas ocultas. Útil si no quieres '
            'verla pero podrías retomarla en el futuro.\n\n'
            '🗑️ Eliminar — la saga desaparece de tu lista de forma permanente '
            'hasta que la recuperes desde Perfil → Más → Sagas ocultas. '
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
            'votación, los miembros votan entre los libros candidatos y el libro ganador '
            'se convierte en la siguiente lectura del club.',
      ),
      _HelpItem(
        pregunta: '¿Cómo se eligen los libros candidatos?',
        respuesta:
            'Los libros candidatos se generan automáticamente. Para que un libro '
            'aparezca como candidato tiene que cumplir tres condiciones: '
            'que al menos 2 miembros del club lo tengan en su biblioteca personal, '
            'que no haya sido ya leído por el club, y que no haya ganado '
            'una edición anterior de Clubvisión.',
      ),
      _HelpItem(
        pregunta: '¿Qué pasa si no hay libros candidatos?',
        respuesta:
            'Si ningún libro cumple las condiciones, Clubvisión no se abre '
            'ese mes y verás un aviso en la pantalla del club explicando '
            'el motivo. Para que haya libros candidatos, al menos dos miembros '
            'tienen que tener el mismo libro en "En mi estantería".',
      ),
      _HelpItem(
        pregunta: '¿Cómo voto?',
        respuesta:
            'Cuando la votación está abierta, entra en Clubvisión '
            'y ordena los libros candidatos según tus preferencias arrastrándolos. '
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
            'Solo quien administra el club puede abrir y cerrar cada edición '
            'de Clubvisión. El resto de miembros solo pueden votar mientras '
            'la votación esté abierta.',
      ),
    ],
  ),
  _HelpSection(
    icono: '🏆',
    titulo: 'Libros del año',
    items: [
      _HelpItem(
        pregunta: '¿En qué se diferencian los Libros del año?',
        respuesta:
            'Tu Libro del año personal es un cuadro privado construido con tus '
            'lecturas mensuales. Las Elecciones de los miembros permiten consultar '
            'esos cuadros personales dentro del club. El Libro del año del club es '
            'una votación colectiva independiente y nunca modifica las elecciones personales.',
      ),
      _HelpItem(
        pregunta: '¿Qué libros participan en la elección del club?',
        respuesta:
            'Solo las lecturas oficiales del club terminadas durante el año. '
            'Quien administra revisa y congela las candidaturas antes de iniciar. '
            'Las lecturas personales, abandonadas o todavía abiertas no participan.',
      ),
      _HelpItem(
        pregunta: '¿Cómo funcionan las fases y los desempates?',
        respuesta:
            'Si hace falta, primero se celebra una clasificación. Después se abre '
            'un cuadro con cuartos, semifinales y final según el número de libros. '
            'Cada miembro puede votar una vez por duelo y cambiar su voto mientras '
            'la ronda esté abierta. Un empate se resuelve mediante una votación específica; '
            'nunca se elige un libro automáticamente.',
      ),
      _HelpItem(
        pregunta: '¿Quién gestiona la elección?',
        respuesta:
            'Solo los roles de administración pueden iniciar la edición y abrir o '
            'cerrar fases. Su voto vale exactamente lo mismo que el del resto. '
            'Los miembros actuales pueden consultar también las ediciones anteriores.',
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
            'comentarios de otros miembros y añadir el tuyo.\n\n'
            'Si hay comentarios que aún no has visto, la app los marca con una '
            'etiqueta "Nuevos" y se desplaza automáticamente hasta ellos al abrir '
            'el capítulo, para que no tengas que bajar a buscarlos.',
      ),
      _HelpItem(
        pregunta: '¿Cómo comento en un capítulo?',
        respuesta:
            'Entra en la lectura activa, selecciona el capítulo '
            'y pulsa el campo de comentario al final. '
            'Puedes responder a comentarios de otros miembros '
            'y reaccionar con emojis. También puedes guardar una cita o añadir '
            'un comentario al actualizar tu progreso.',
      ),
      _HelpItem(
        pregunta: '¿Puedo reaccionar a las respuestas de un comentario?',
        respuesta:
            'Sí. Las respuestas tienen el mismo selector completo de reacciones '
            'que los comentarios principales: pulsa el botón de emoji en la '
            'respuesta para elegir tu reacción. También puedes cambiarla '
            'o quitarla pulsando de nuevo. Pulsa el resumen de reacciones para '
            'ver quién ha reaccionado con cada emoji.',
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
            'El Kit de lectura es tu espacio personal para preparar la experiencia '
            'lectora de cada libro. Tiene 6 secciones: paleta de colores, '
            'subrayadores, atmósfera, playlist, wallpaper y story.\n\n'
            'Lo encontrarás en la ficha de cada libro como una tarjeta con barra de '
            'progreso. Consulta la sección "Kit de lectura" de esta ayuda para ver '
            'todas las opciones disponibles.',
      ),
    ],
  ),
  _HelpSection(
    icono: '✨',
    titulo: 'Kit de lectura',
    items: [
      _HelpItem(
        pregunta: '¿Qué secciones tiene el Kit de lectura?',
        respuesta:
            'El Kit de lectura tiene 6 secciones que puedes completar a tu ritmo:\n\n'
            '🎨 Paleta — colores que definen el ambiente visual del libro, con '
            'tus post-its y la leyenda de lectura.\n'
            '✏️ Subrayadores — set de 5 marcadores con una propuesta de uso '
            'para anotar el libro físico.\n'
            '🌙 Atmósfera — el entorno ideal: luz, bebida, snack y momento del día.\n'
            '🎵 Playlist — música para acompañar la lectura.\n'
            '🖼️ Wallpaper — fondo de pantalla generado con los colores del libro.\n'
            '📱 Story — imagen editorial para compartir en redes.\n\n'
            'La tarjeta del kit muestra una barra de progreso con cuántas secciones '
            'llevas preparadas (ej. "3 de 6 preparadas"). El CTA cambia según avanzas: '
            '"Preparar mi lectura" → "Continúa preparando tu kit" → "Ver mi kit completo".',
      ),
      _HelpItem(
        pregunta: '¿Cómo accedo al Kit de lectura?',
        respuesta:
            'Desde la ficha de cualquier libro en tu biblioteca, desplázate hasta '
            'la tarjeta "Kit de lectura" y pulsa sobre ella.\n\n'
            'Si el libro tiene atmósfera configurada, verás también un banner encima '
            'de la tarjeta del kit con el nombre y emoji de la atmósfera.',
      ),
      _HelpItem(
        pregunta: '¿Qué son los subrayadores del Kit?',
        respuesta:
            'Son una propuesta de 5 colores para anotar el libro físico, '
            'cada uno con un significado:\n\n'
            '• Color 1 — Momentos favoritos\n'
            '• Color 2 — Teorías e ideas\n'
            '• Color 3 — Citas\n'
            '• Color 4 — Personajes\n'
            '• Color 5 — Impacto\n\n'
            'Los colores están inspirados en los Zebra Mildliner — el subrayador '
            'favorito de BookTok y Bookstagram, con punta dual (ancha + fina) y '
            '40 tonos pastel que no manchan el papel fino. Dentro de la página de '
            'subrayadores encontrarás un enlace a Amazon para comprarlos en físico.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la Paleta de lectura?',
        respuesta:
            'La Paleta de lectura muestra los colores que representan el ambiente '
            'visual del libro. Dentro encontrarás dos secciones:\n\n'
            '🟡 Tus post-its — marcadores temáticos (favoritos, citas, teorías, '
            'personajes, impacto) para organizar tus anotaciones visualmente.\n\n'
            '📖 La leyenda de lectura — el significado de cada color del set.\n\n'
            'Al generar el Story, los post-its aparecen en cascada junto a la portada '
            'del libro, creando una imagen editorial lista para Instagram.',
      ),
      _HelpItem(
        pregunta: '¿Qué es el Story del Kit?',
        respuesta:
            'El Story es una imagen de formato 9:16 (vertical, ideal para Instagram) '
            'generada con los elementos de tu kit:\n\n'
            '• Portada del libro a la izquierda, inclinada ligeramente\n'
            '• 5 post-its en cascada a la derecha con tus categorías de anotación\n'
            '• Puntos de la paleta de color en la esquina superior\n'
            '• Fila de subrayadores Mildliner en la parte inferior\n'
            '• Título y nombre del club "CLUBREADS"\n\n'
            'Puedes guardarla en tu galería o compartirla directamente desde la app.',
      ),
      _HelpItem(
        pregunta: '¿Qué pasa cuando marco un libro como "Leyendo"?',
        respuesta:
            'Si el libro no tiene kit de lectura preparado, la app te invitará '
            'a prepararlo antes de empezar. Puedes hacerlo en ese momento o postponerlo '
            'y acceder más tarde desde la ficha del libro.',
      ),
      _HelpItem(
        pregunta: '¿Qué pasa cuando termino un libro?',
        respuesta:
            'Al marcar un libro como "Historia terminada", si tienes la paleta '
            'de colores preparada, la app te propondrá generar tu Story para '
            'compartir el momento en redes sociales.\n\n'
            'También se muestra la celebración habitual con confeti, '
            'y el libro pasa inmediatamente a tu historial con su valoración.',
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
        pregunta: '📚 Categoría Lector — ¿cómo se desbloquea?',
        respuesta:
            'Estos logros se consiguen terminando libros:\n\n'
            '📖 Primer libro — completa 1 lectura\n'
            '📚 Lector en marcha — llega a 5 libros terminados\n'
            '🔟 Lector habitual — alcanza 10 libros finalizados\n'
            '🌟 Lector voraz (Raro) — 25 libros en tu historial\n'
            '🏆 Biblióvora (Épico) — 50 libros completados\n'
            '💯 Lector centenario (Legendario) — 100 libros. Una hazaña.',
      ),
      _HelpItem(
        pregunta: '📄 Categoría Páginas — ¿cómo se desbloquea?',
        respuesta:
            'Se calculan sumando las páginas de todos tus libros terminados:\n\n'
            '📄 Mil páginas — supera las 1.000 páginas leídas\n'
            '📃 Lector resistente (Raro) — 5.000 páginas\n'
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
            'Premian la intensidad de lectura en períodos cortos:\n\n'
            '🔥 Mes intenso (Raro) — 5 libros en un mismo mes\n'
            '⚡ Maratoniana (Épico) — 10 libros en un mes\n'
            '🗓️ Gran año lector (Raro) — 50 libros en un año\n'
            '🏅 Año legendario (Legendario) — 100 libros en un solo año',
      ),
      _HelpItem(
        pregunta: '¿Qué es el Reto lector?',
        respuesta:
            'El Reto lector te permite marcarte un objetivo personal de libros '
            'para el año en curso. El progreso se actualiza automáticamente '
            'según vas finalizando libros en tu biblioteca.\n\n'
            '📖 En modo personal — el reto es tuyo y privado. Ves tu progreso '
            'y puedes modificar el objetivo en cualquier momento.\n\n'
            '👥 En modo club — cada miembro tiene su propio reto. Puedes ver '
            'el avance de todos ordenado por porcentaje de cumplimiento. '
            'Quienes han superado su reto aparecen con 🏆.\n\n'
            'Además existe un reto colectivo de club: la suma de todos los objetivos '
            'individuales. Si entre todas lo superáis, se celebra con un logro especial.\n\n'
            'Para crear o cambiar tu reto, entra en "Reto lector" y pulsa '
            '"Crear reto" o "Cambiar objetivo".',
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
            'Es el botón con el que confirmas expresamente que has leído hoy. '
            'Abrir la aplicación, visitar el dashboard o actualizar una pantalla '
            'no hace check-in ni aumenta la racha.\n\n'
            'Lo encontrarás en:\n'
            '• Modo personal → pestaña "Mi espacio"\n'
            '• Cualquier modo → tu Perfil → sección "Seguimiento de lectura"',
      ),
      _HelpItem(
        pregunta: '¿Cómo funciona la racha de lectura?',
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
            'de lectura durante el año: cada cuadrado representa un día y su '
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
            'Toca a la derecha para avanzar y a la izquierda para retroceder. '
            'Se abre desde Perfil → Favoritos. La tarjeta solo está activa durante '
            'su periodo de disponibilidad; fuera de él aparece con candado. En enero '
            'muestra el resumen del año anterior. La regla es igual con o sin club.',
      ),
      _HelpItem(
        pregunta: '¿Están disponibles en modo club también?',
        respuesta:
            'Sí. Son funciones personales y no requieren pertenecer a un club. '
            'El check-in, la racha y el mapa de calor están en Perfil → Resumen → '
            'Seguimiento de lectura y también en "Mi espacio". Wrapped está en '
            'Perfil → Favoritos y mantiene las mismas reglas de disponibilidad.',
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
            'Las atmósferas definen el entorno ideal para leer: el tipo de luz, '
            'la bebida, el snack y el momento del día. Puedes configurar tu propia '
            'atmósfera personal para cada libro dentro de su Kit de lectura.\n\n'
            'Si tienes atmósfera preparada en tu libro activo, verás un banner con '
            'el entorno encima del Kit de lectura en la ficha del libro.\n\n'
            'En modo club, quien administra también puede activar una atmósfera visual '
            'global para toda la comunidad desde la sección Atmósferas de la lectura activa.',
      ),
      _HelpItem(
        pregunta: '¿Cómo cambio mi avatar o foto de perfil?',
        respuesta:
            'Ve a tu perfil y pulsa sobre tu avatar. Podrás elegir '
            'un color y un icono, o subir una foto desde tu galería.\n\n'
            'Al subir una foto desde la galería, la carga puede tardar '
            'unos segundos porque la imagen se optimiza antes de guardarse. '
            'Espera hasta que aparezca el mensaje de confirmación antes '
            'de cerrar la pantalla.',
      ),
      _HelpItem(
        pregunta: '¿Puedo personalizar mi perfil?',
        respuesta:
            'Sí. En tu perfil puedes editar tu avatar, ver tus estadísticas '
            'de lectura, tu historial, los géneros favoritos, '
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
            'El Perfil usa las mismas secciones con o sin club: Resumen, Historial, '
            'Favoritos, Meses lectores, Logros y Más.\n\n'
            '"Resumen" reúne Mi biblioteca, Historia lectora, Seguimiento de lectura '
            'y Géneros favoritos.\n\n'
            '"Historial" tiene dos vistas. Cronología muestra libros, relecturas, '
            'hitos y sagas completadas; Libros reúne las lecturas finalizadas y '
            'abandonadas. El selector de año permite revisar periodos anteriores. '
            'En tu perfil puedes abrir y editar cada lectura concreta, incluidas las '
            'relecturas; en perfiles ajenos todo es de consulta.\n\n'
            '"Favoritos" reúne Libros favoritos, Mi libro del año y Wrapped.\n\n'
            '"Meses lectores" muestra un calendario por cada mes en el que has '
            'leído algún libro, con las portadas colocadas en los días que las terminaste.\n\n'
            '"Logros" muestra todas tus medallas agrupadas por categoría, '
            'con barra de progreso y estado de desbloqueo. "Más" contiene opciones '
            'secundarias como Sagas ocultas, importaciones, Ayuda y ajustes.',
      ),
      _HelpItem(
        pregunta: '¿Cómo funciona “Mi libro del año”?',
        respuesta:
            'En Perfil → Favoritos → Mi libro del año puedes elegir, para cada mes, '
            'entre los libros que terminaste durante ese mes. Las relecturas '
            'finalizadas también son válidas y un mismo libro solo aparece una vez '
            'por mes. Los meses futuros permanecen bloqueados.\n\n'
            'Las elecciones mensuales forman un cuadro eliminatorio. Cuando una ronda '
            'esté disponible, debes elegir expresamente cada libro ganador; ninguno '
            'avanza solo. Si cambias una selección anterior, se te avisará antes de '
            'invalidar las decisiones posteriores que dependan de ella.\n\n'
            'Puedes cambiar de año en el cuadro completo. En perfiles ajenos se muestra '
            'en modo de consulta y se oculta si todavía no hay ninguna selección.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la tarjeta "Favoritos del club"?',
        respuesta:
            'Es una tarjeta del dashboard (modo club) que muestra los 5 libros '
            'favoritos de cada miembro de tu club.\n\n'
            'Verás el avatar de cada miembro con las portadas de sus favoritos '
            'encima. La tarjeta te muestra primero a "Tú" con tus propios favoritos, '
            'y luego al resto de miembros que tengan al menos uno marcado.\n\n'
            'Pulsa sobre el avatar de cualquier miembro para ver su lista completa '
            'de favoritos con título, autor y género.\n\n'
            'Para que aparezca necesitas tener al menos un libro marcado como '
            'favorito ♥ en tu biblioteca.',
      ),
      _HelpItem(
        pregunta: '¿Puedo exportar mi biblioteca?',
        respuesta:
            'Sí. Ve a Perfil → pestaña "Más" → "Exportar mi biblioteca". '
            'Se generará un archivo CSV con todos tus libros: título, autor, '
            'saga, estado, género, formato, páginas, tu valoración, reseña, '
            'fechas de inicio y fin, y si es relectura.\n\n'
            'El archivo se puede abrir en Excel, Google Sheets o cualquier '
            'aplicación de hojas de cálculo. También puedes compartirlo '
            'directamente desde el selector de apps del sistema.',
      ),
      _HelpItem(
        pregunta: '¿Cómo funcionan las notificaciones?',
        respuesta:
            'Recibirás notificaciones dentro de la app (campanita en el dashboard) '
            'cuando ocurra algo relevante en tu club: nueva lectura oficial, '
            'nuevo miembro, resultado de Clubvisión, nuevo libro en la biblioteca '
            'o cuando alguien comenta en una lectura en la que participas.',
      ),
      _HelpItem(
        pregunta: '¿Qué es "Seguimiento de lectura" en el perfil?',
        respuesta:
            'Es un bloque de Resumen, visible en tu propio perfil, que agrupa el '
            'check-in diario, la racha y el mapa de calor anual. Está disponible '
            'con o sin club. Wrapped no está aquí: se encuentra en Favoritos.',
      ),
    ],
  ),
  _HelpSection(
    icono: '✨',
    titulo: 'Funciones especiales',
    items: [
      _HelpItem(
        pregunta: '¿Qué es la Ruleta del TBR?',
        respuesta:
            'La Ruleta del TBR es una tarjeta en "Mi universo lector" que elige '
            'al azar un libro de tu lista de pendientes. Es perfecta para '
            'cuando tienes muchos libros en la pila y no sabes cuál leer a continuación.\n\n'
            'Pulsa "Girar la ruleta" y la animación tipo tragaperras irá pasando '
            'portadas hasta detenerse en tu siguiente lectura. Después puedes '
            'abrir la ficha del libro o volver a girar si no te convence.',
      ),
      _HelpItem(
        pregunta: '¿En qué se diferencia el modo Tarro?',
        respuesta:
            'El Tarro es la versión más artesanal de la ruleta. Imagina un tarro '
            'de cristal con papelitos doblados dentro: al agitarlo, uno sale al azar.\n\n'
            'En la animación verás los papelitos moviéndose dentro del tarro '
            'mientras se revuelve, y el resultado aparece escrito a mano en un '
            'papelito de papel rayado.\n\n'
            'Cambia entre Ruleta y Tarro con el selector que hay en la parte '
            'superior de la tarjeta. Ambos modos eligen el mismo libro al azar; '
            'solo cambia la experiencia visual.',
      ),
      _HelpItem(
        pregunta: '¿Qué es el Vibe Reader?',
        respuesta:
            'El Vibe Reader es un filtro de estado de ánimo que aparece en tu '
            'biblioteca cuando tienes activa la pestaña "Pendientes".\n\n'
            'Elige un vibe — oscuro, ligero, romántico, de pensar, intenso o de llorar — '
            'y la biblioteca filtra automáticamente los libros pendientes cuyos géneros '
            'encajan con ese estado de ánimo. Es una forma de encontrar la lectura '
            'perfecta para cómo te sientes ahora mismo.\n\n'
            'Pulsa "Quitar filtro" para ver todos los pendientes de nuevo. '
            'El filtro se limpia solo al cambiar de pestaña.',
      ),
      _HelpItem(
        pregunta: '¿Qué es el Quiz de Personalidad Lectora?',
        respuesta:
            'Es un cuestionario de 6 preguntas que descubre tu arquetipo lector. '
            'Responde sobre tus hábitos, preferencias y momentos de lectura, y la app '
            'calcula cuál de estos seis perfiles te define mejor:\n\n'
            '🌙 Lectora Nocturna · 📚 Maratonista · 💕 Romántica Empedernida · '
            '🧠 Lectora Reflexiva · ⚡ Imparable · 🎨 Estética\n\n'
            'Cada resultado incluye una descripción y una tarjeta compartible con '
            'tu arquetipo. Puedes compartirla directamente desde el resultado.\n\n'
            'Tu resultado se guarda automáticamente; la próxima vez que abras el quiz '
            'verás tu arquetipo directamente sin repetir las preguntas. '
            'Pulsa "Repetir" si quieres volver a hacerlo.\n\n'
            'Lo encontrarás en "Mi espacio" → sección central, o en tu perfil → '
            'pestaña Favoritos.',
      ),
      _HelpItem(
        pregunta: '¿Qué son las Personalidades del club?',
        respuesta:
            'Es una tarjeta en "El Club" que reúne los arquetipos lectores de '
            'todas las miembros que han completado el Quiz de Personalidad.\n\n'
            'Verás el arquetipo más común del club (el "arquetipo del club"), '
            'cuántas miembros lo comparten, y un scroll horizontal con el avatar, '
            'el emoji del arquetipo y el nombre de cada una.\n\n'
            'Si nadie ha hecho el quiz aún, aparece un banner invitándote a ser la '
            'primera. Cuando hagas el quiz, tu resultado aparecerá automáticamente '
            'en esta tarjeta la próxima vez que abras el dashboard del club.',
      ),
      _HelpItem(
        pregunta: '¿Cómo funciona el orden Arcoíris en la estantería anual?',
        respuesta:
            'El orden Arcoíris reorganiza tu estantería anual ordenando las portadas '
            'por su color dominante: de los rojos al naranja, amarillo, verde, azul '
            'y morado, creando un degradado de colores con tus propias lecturas.\n\n'
            'Para activarlo, abre el menú ⋮ de la estantería anual (en tu perfil, '
            'pestaña Resumen) y elige "🌈 Arcoíris". La primera vez extrae los '
            'colores de todas las portadas, lo que puede tardar unos segundos; '
            'después se guarda en caché y es instantáneo.',
      ),
      _HelpItem(
        pregunta: '¿Cómo comparto mi tarjeta lectora?',
        respuesta:
            'La tarjeta lectora es una imagen personalizada con tu nombre, '
            'estadísticas clave (libros leídos, racha, género favorito) y una '
            'tira de tus portadas recientes. Puedes compartirla en redes sociales '
            'o enviarla por donde quieras.\n\n'
            'Para generarla, ve a:\n'
            '• "Mi espacio" → botón "Comparte tu perfil lector"\n'
            '• Tu perfil → pestaña Favoritos → "Comparte tu perfil lector"\n\n'
            'Pulsa "Compartir tarjeta" y elige la app con la que enviarla. '
            'La imagen se genera automáticamente con tus datos actuales.',
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
        child: Material(
          color: Colors.transparent,
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
      child: Material(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
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
