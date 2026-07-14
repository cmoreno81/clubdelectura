enum AtmosferaLectura {
  neutra,
  magica,
  oscura,
  romantica,
  misteriosa,
  gotica,
  bosque,
  marina,
  epica,
  acogedora,
  futurista,
  historica,
}

enum TemporadaVisual { primavera, verano, otono, invierno, navidad }

extension AtmosferaLecturaParser on AtmosferaLectura {
  String get apiValue {
    return switch (this) {
      AtmosferaLectura.neutra => 'NEUTRA',
      AtmosferaLectura.magica => 'MAGICA',
      AtmosferaLectura.oscura => 'OSCURA',
      AtmosferaLectura.romantica => 'ROMANTICA',
      AtmosferaLectura.misteriosa => 'MISTERIOSA',
      AtmosferaLectura.gotica => 'GOTICA',
      AtmosferaLectura.bosque => 'BOSQUE',
      AtmosferaLectura.marina => 'MARINA',
      AtmosferaLectura.epica => 'EPICA',
      AtmosferaLectura.acogedora => 'ACOGEDORA',
      AtmosferaLectura.futurista => 'FUTURISTA',
      AtmosferaLectura.historica => 'HISTORICA',
    };
  }

  static AtmosferaLectura fromApi(String? value) {
    final normalizado = value?.trim().toUpperCase() ?? '';

    return switch (normalizado) {
      'MAGICA' || 'MÁGICA' => AtmosferaLectura.magica,
      'OSCURA' => AtmosferaLectura.oscura,
      'ROMANTICA' || 'ROMÁNTICA' => AtmosferaLectura.romantica,
      'MISTERIOSA' || 'MISTERIO' => AtmosferaLectura.misteriosa,
      'GOTICA' || 'GÓTICA' => AtmosferaLectura.gotica,
      'BOSQUE' => AtmosferaLectura.bosque,
      'MARINA' || 'MAR' => AtmosferaLectura.marina,
      'EPICA' || 'ÉPICA' => AtmosferaLectura.epica,
      'ACOGEDORA' || 'COZY' => AtmosferaLectura.acogedora,
      'FUTURISTA' || 'CIENCIA_FICCION' => AtmosferaLectura.futurista,
      'HISTORICA' || 'HISTÓRICA' => AtmosferaLectura.historica,
      _ => AtmosferaLectura.neutra,
    };
  }
}

extension TemporadaVisualResolver on TemporadaVisual {
  static TemporadaVisual desdeFecha(DateTime fecha) {
    final mes = fecha.month;
    final dia = fecha.day;

    // Navidad prevalece sobre invierno.
    if (mes == 12 || (mes == 1 && dia <= 6)) {
      return TemporadaVisual.navidad;
    }

    if (mes >= 3 && mes <= 5) {
      return TemporadaVisual.primavera;
    }

    if (mes >= 6 && mes <= 8) {
      return TemporadaVisual.verano;
    }

    if (mes >= 9 && mes <= 11) {
      return TemporadaVisual.otono;
    }

    return TemporadaVisual.invierno;
  }
}
