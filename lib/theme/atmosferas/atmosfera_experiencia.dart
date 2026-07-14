import 'package:flutter/material.dart';

import 'atmosfera_paleta.dart';
import 'atmosfera_tipo.dart';

class AtmosferaExperiencia {
  final AtmosferaLectura tipo;
  final String titulo;
  final String descripcion;
  final String icono;

  final String luz;
  final String bebida;
  final String snack;
  final String musica;
  final String momento;
  final String moodBookstagram;

  final List<String> etiquetas;

  const AtmosferaExperiencia({
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.luz,
    required this.bebida,
    required this.snack,
    required this.musica,
    required this.momento,
    required this.etiquetas,
    required this.moodBookstagram,
  });

  AtmosferaPaleta get paleta {
    return AtmosferaPaletas.lectura(tipo);
  }
}

class AtmosferaExperiencias {
  const AtmosferaExperiencias._();

  static AtmosferaExperiencia desdeTipo(AtmosferaLectura tipo) {
    return switch (tipo) {
      AtmosferaLectura.neutra => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.neutra,
        titulo: 'Lectura relajada',
        descripcion:
            'Una atmósfera limpia y tranquila para disfrutar del libro sin distracciones.',
        icono: '📖',
        luz: 'Luz natural o lámpara cálida',
        bebida: 'Tu bebida favorita',
        snack: 'Algo ligero y dulce',
        musica: 'Lo-fi instrumental o silencio',
        momento: 'Cualquier momento del día',
        moodBookstagram:
            'Libro abierto · taza blanca · manta neutra · post-it crema',
        etiquetas: ['Minimalista', 'Relajante', 'Versátil'],
      ),

      AtmosferaLectura.magica => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.magica,
        titulo: 'Noche de estrellas y hechizos',
        descripcion:
            'Destellos, secretos y una sensación de que cualquier cosa puede suceder.',
        icono: '✨',
        luz: 'Guirnaldas o luz violeta muy suave',
        bebida: 'Té floral o bebida brillante',
        snack: 'Chocolate blanco o caramelos',
        musica: 'Fantasy instrumental y piano etéreo',
        momento: 'Al anochecer',
        etiquetas: ['Encantada', 'Soñadora', 'Fantástica'],
        moodBookstagram: 'Cristales · velas · té violeta · post-it lavanda',
      ),

      AtmosferaLectura.oscura => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.oscura,
        titulo: 'Medianoche entre sombras',
        descripcion: 'Una lectura intensa, silenciosa y ligeramente peligrosa.',
        icono: '🌑',
        luz: 'Lámpara tenue y luz indirecta',
        bebida: 'Café oscuro o té negro',
        snack: 'Chocolate negro',
        musica: 'Dark ambient y cuerdas graves',
        momento: 'De noche, cuando todo está en silencio',
        etiquetas: ['Intensa', 'Sombría', 'Magnética'],
        moodBookstagram:
            'Velas negras · anotaciones oscuras · café · luz tenue',
      ),

      AtmosferaLectura.romantica => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.romantica,
        titulo: 'Atardecer de corazones',
        descripcion:
            'Una experiencia cálida, emocional y llena de pequeños momentos para suspirar.',
        icono: '💗',
        luz: 'Luz rosada o cálida',
        bebida: 'Infusión dulce, limonada o cacao',
        snack: 'Fresas, chocolate o galletas',
        musica: 'Indie romántico y acústicos suaves',
        momento: 'Una tarde lenta o antes de dormir',
        etiquetas: ['Emocional', 'Dulce', 'Romántica'],
        moodBookstagram:
            'Manta beige · flores secas · taza blanca · post-it rosa',
      ),

      AtmosferaLectura.misteriosa => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.misteriosa,
        titulo: 'Niebla, pistas y secretos',
        descripcion:
            'Cada detalle puede significar algo y ninguna sospecha parece casual.',
        icono: '🌫️',
        luz: 'Luz fría y focal',
        bebida: 'Café, té especiado o agua con hielo',
        snack: 'Frutos secos o chocolate',
        musica: 'Piano de suspense y ambient cinematográfico',
        momento: 'Tarde lluviosa o noche',
        etiquetas: ['Intrigante', 'Enigmática', 'Tensa'],
        moodBookstagram: 'Sombras suaves · café oscuro · libreta negra',
      ),

      AtmosferaLectura.gotica => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.gotica,
        titulo: 'Velas en una mansión antigua',
        descripcion:
            'Belleza decadente, secretos familiares y rincones donde parece habitar el pasado.',
        icono: '🕯️',
        luz: 'Velas LED o luz ámbar muy tenue',
        bebida: 'Té negro, vino sin alcohol o cacao',
        snack: 'Chocolate amargo o frutos rojos',
        musica: 'Piano oscuro, violonchelo y lluvia',
        momento: 'Noche fría o tormentosa',
        etiquetas: ['Gótica', 'Elegante', 'Melancólica'],
        moodBookstagram:
            'Biblioteca antigua · vela · post-it berenjena · encaje',
      ),

      AtmosferaLectura.bosque => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.bosque,
        titulo: 'Refugio entre árboles',
        descripcion:
            'Hojas, madera, tierra húmeda y una lectura que se siente lejos del ruido.',
        icono: '🌲',
        luz: 'Luz verde suave o natural',
        bebida: 'Té de hierbas o sidra',
        snack: 'Frutos secos y galletas de avena',
        musica: 'Sonidos de bosque y folk instrumental',
        momento: 'Mañana tranquila o tarde de lluvia',
        etiquetas: ['Natural', 'Mística', 'Silvestre'],
        moodBookstagram: 'Plantas · té verde · madera · post-it salvia',
      ),

      AtmosferaLectura.marina => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.marina,
        titulo: 'Brisa junto al mar',
        descripcion:
            'Una experiencia fresca, luminosa y con el ritmo constante de las olas.',
        icono: '🌊',
        luz: 'Luz azul clara o natural',
        bebida: 'Limonada, agua fría o té helado',
        snack: 'Fruta fresca o algo salado',
        musica: 'Olas, acústicos y chill suave',
        momento: 'Mañana luminosa o atardecer',
        etiquetas: ['Fresca', 'Libre', 'Marina'],
        moodBookstagram: 'Taza azul · conchas · luz natural · post-it turquesa',
      ),

      AtmosferaLectura.epica => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.epica,
        titulo: 'Antes de la gran batalla',
        descripcion:
            'Mapas desplegados, juramentos, destinos imposibles y música que pide subir el volumen.',
        icono: '⚔️',
        luz: 'Luz dorada o rojiza',
        bebida: 'Café, té especiado o bebida energética',
        snack: 'Frutos secos, pan tostado o chocolate',
        musica: 'Bandas sonoras épicas y coros',
        momento: 'Cuando tengas tiempo para leer sin interrupciones',
        etiquetas: ['Heroica', 'Aventurera', 'Poderosa'],
        moodBookstagram: 'Mapa fantástico · café · vela ámbar · cuero',
      ),

      AtmosferaLectura.acogedora => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.acogedora,
        titulo: 'Manta, lluvia y páginas',
        descripcion:
            'Una lectura cómoda y cálida que convierte cualquier rincón en refugio.',
        icono: '☕',
        luz: 'Lámpara cálida y suave',
        bebida: 'Café con leche, cacao o té chai',
        snack: 'Galletas, bizcocho o canela',
        musica: 'Jazz suave, lluvia o lo-fi',
        momento: 'Tarde de lluvia o antes de dormir',
        etiquetas: ['Cozy', 'Cálida', 'Reconfortante'],
        moodBookstagram: 'Manta suave · canela · café con leche · luz cálida',
      ),

      AtmosferaLectura.futurista => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.futurista,
        titulo: 'Luces de neón y otros mundos',
        descripcion:
            'Tecnología, estrellas lejanas y la sensación de estar leyendo desde el futuro.',
        icono: '🚀',
        luz: 'Luz azul, violeta o neón',
        bebida: 'Bebida fría o café',
        snack: 'Palomitas, frutos secos o caramelos',
        musica: 'Synthwave, electrónica ambiental y sci-fi',
        momento: 'Por la noche',
        etiquetas: ['Cósmica', 'Tecnológica', 'Futurista'],
        moodBookstagram: 'Auriculares · luz fría · libreta minimalista',
      ),

      AtmosferaLectura.historica => const AtmosferaExperiencia(
        tipo: AtmosferaLectura.historica,
        titulo: 'Cartas de otro tiempo',
        descripcion:
            'Papel envejecido, memoria y una historia que abre una ventana al pasado.',
        icono: '📜',
        luz: 'Luz cálida tipo escritorio',
        bebida: 'Té clásico, café o infusión',
        snack: 'Galletas de mantequilla o frutos secos',
        musica: 'Piano, música clásica o ambiente de época',
        momento: 'Una tarde tranquila',
        etiquetas: ['Clásica', 'Nostálgica', 'Histórica'],
        moodBookstagram: 'Cuaderno vintage · té negro · flores prensadas',
      ),
    };
  }

  static List<AtmosferaExperiencia> get todas {
    return AtmosferaLectura.values
        .where((tipo) => tipo != AtmosferaLectura.neutra)
        .map(desdeTipo)
        .toList(growable: false);
  }

  static AtmosferaExperiencia desdeId(String? id) {
    final tipo = AtmosferaLecturaParser.fromApi(id);

    return desdeTipo(tipo);
  }

  static Color colorTextoSobre(Color color) {
    return color.computeLuminance() > 0.46 ? Colors.black87 : Colors.white;
  }
}
