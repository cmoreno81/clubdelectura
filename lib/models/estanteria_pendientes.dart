/// "Estantería de pendientes": de los libros pendientes de una lectora, los
/// que ya tiene. Papel y sin formato cuentan como físico; ebook y audiolibro
/// se suman aparte.
class EstanteriaPendientes {
  const EstanteriaPendientes({
    required this.pendientes,
    required this.tengo,
    required this.enEstanteria,
    required this.otrosFormatos,
    required this.serie,
    this.anio = 0,
    this.leidosAnio = 0,
    this.leidosEnCasaAnio = 0,
    this.entraronAnio = 0,
    this.terminadosPapelAnio = 0,
    this.terminadosSinFormatoAnio = 0,
  });

  /// Balance del año en curso: pendientes que ha empezado o leído (de ellos,
  /// los que ya tenía en casa) frente a los que han entrado nuevos.
  final int anio;
  final int leidosAnio;
  final int leidosEnCasaAnio;
  final int entraronAnio;

  /// Libros terminados este año en papel o sin formato, vinieran o no de la
  /// pila de pendientes.
  final int terminadosPapelAnio;

  /// Lecturas terminadas este año sin formato apuntado (cuentan como papel).
  final int terminadosSinFormatoAnio;

  /// Pendientes que han salido de la pila menos los que han entrado: negativo
  /// si la pila ha crecido.
  int get balanceAnio => leidosAnio - entraronAnio;

  /// Todos los pendientes de la biblioteca.
  final int pendientes;

  /// Pendientes que ya tiene (cualquier formato).
  final int tengo;

  /// De esos, los que están en papel o sin formato.
  final int enEstanteria;
  final int otrosFormatos;

  /// Pendientes al final de cada mes, del más antiguo al actual.
  final List<PuntoPila> serie;

  /// Cuántos pendientes aún no tiene.
  int get faltan => (pendientes - tengo).clamp(0, pendientes);

  /// La línea solo tiene sentido cuando hay al menos dos meses con datos.
  bool get hayHistorial => serie.where((p) => p.pila > 0).length >= 2;

  /// Cuántos pendientes más (+) o menos (−) hay que a final del mes pasado.
  int get cambioMes =>
      serie.length < 2 ? 0 : pendientes - serie[serie.length - 2].pila;

  static EstanteriaPendientes? fromJson(Map<String, dynamic> data) {
    if (data['ok'] != true) return null;
    int entero(Object? v) => v is num ? v.toInt() : 0;
    return EstanteriaPendientes(
      pendientes: entero(data['pendientes']),
      tengo: entero(data['tengo']),
      enEstanteria: entero(data['enEstanteria']),
      otrosFormatos: entero(data['otrosFormatos']),
      anio: entero((data['anio'] as Map?)?['anio']),
      leidosAnio: entero((data['anio'] as Map?)?['leidos']),
      leidosEnCasaAnio: entero((data['anio'] as Map?)?['leidosEnCasa']),
      entraronAnio: entero((data['anio'] as Map?)?['entraron']),
      terminadosPapelAnio: entero(data['terminadosPapel']),
      terminadosSinFormatoAnio: entero(data['terminadosSinFormato']),
      serie: [
        for (final p in (data['serie'] as List? ?? const []))
          if (p is Map)
            PuntoPila(mes: p['mes']?.toString() ?? '', pila: entero(p['pila'])),
      ],
    );
  }
}

class PuntoPila {
  const PuntoPila({required this.mes, required this.pila});

  /// "2026-10".
  final String mes;
  final int pila;
}
