import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/estanteria_pendientes.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/comprar_libros_page.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// "Tu pila de pendientes": un contador con lo que sube o baja cada mes y el
/// balance del año (pendientes en papel leídos frente a los que tienes en
/// casa sin leer). En el perfil de otra lectora del club ([usuario]) se
/// ve igual pero sin el enlace a comprar.
class EstanteriaPendientesCard extends StatefulWidget {
  const EstanteriaPendientesCard({super.key, this.usuario = ''});

  /// Vacío = la propia lectora.
  final String usuario;

  @override
  State<EstanteriaPendientesCard> createState() =>
      _EstanteriaPendientesCardState();
}

class _EstanteriaPendientesCardState extends State<EstanteriaPendientesCard> {
  EstanteriaPendientes? _datos;
  int _peticion = 0;

  bool get _propia => widget.usuario.isEmpty;

  @override
  void initState() {
    super.initState();
    // "Ya lo tengo" se marca en otras pantallas.
    WishlistService.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void didUpdateWidget(covariant EstanteriaPendientesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usuario != widget.usuario) _cargar();
  }

  @override
  void dispose() {
    WishlistService.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final peticion = ++_peticion;
    try {
      final datos = await ApiService().getEstanteriaPendientes(
        usuario: widget.usuario,
      );
      if (!mounted || peticion != _peticion) return;
      setState(() => _datos = datos);
    } catch (_) {
      // Sin datos se deja la tarjeta como estaba (o sin tarjeta).
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _datos;
    if (d == null || (d.pendientes == 0 && d.tengo == 0)) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stacked_bar_chart_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _propia ? 'Tu pila de pendientes' : 'Su pila de pendientes',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Contador(datos: d),
          const SizedBox(height: 16),
          BalanceAnualPila(datos: d),
          const SizedBox(height: 10),
          _NotaFormato(sinFormato: _propia ? d.terminadosSinFormatoAnio : 0),
          if (_propia && d.faltan > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.push<void>(
                  context,
                  AppPageRoute(
                    builder: (_) => const ComprarLibrosPage(pestanaInicial: 1),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                iconAlignment: IconAlignment.end,
                label: const Text('Ver lo que me falta por comprar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// Contador grande con la variación respecto a final del mes pasado.
class _Contador extends StatelessWidget {
  const _Contador({required this.datos});

  final EstanteriaPendientes datos;

  @override
  Widget build(BuildContext context) {
    final cambio = datos.cambioMes;
    final baja = cambio < 0;
    final color = cambio == 0
        ? AppColors.textSecondary
        : baja
        ? AppColors.success
        : AppColors.inkCoral;
    final texto = cambio == 0
        ? 'Igual que el mes pasado'
        : '${cambio.abs()} ${baja ? 'menos' : 'más'} que a final del mes pasado';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${datos.pendientes}',
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 46,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'pendientes',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (datos.serie.length >= 2)
                  Row(
                    children: [
                      Icon(
                        cambio == 0
                            ? Icons.remove_rounded
                            : baja
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          texto,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Balance del año: pendientes que has sacado de la pila (empezados o
/// leídos) frente a los que han entrado nuevos.
@visibleForTesting
class BalanceAnualPila extends StatelessWidget {
  const BalanceAnualPila({required this.datos});

  final EstanteriaPendientes datos;

  @override
  Widget build(BuildContext context) {
    final anio = datos.anio == 0 ? DateTime.now().year : datos.anio;
    final enCasa = datos.enEstanteria;
    // Sin libros en casa ni pendientes sacados, las barras vacías no dicen
    // nada: se explica para qué sirve en vez de enseñar ceros.
    if (enCasa == 0 && datos.leidosAnio == 0) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4E7D3).withValues(alpha: .55),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Marca «Ya lo tengo» en tus pendientes y verás aquí cuántos '
                'tienes en casa y cómo los vas leyendo.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final String mensaje;
    final Color color;
    if (datos.leidosAnio > 0) {
      mensaje =
          'En $anio has sacado ${datos.leidosAnio} de la pila'
          '${enCasa > 0 ? '; te quedan $enCasa en casa' : ''}';
      color = AppColors.success;
    } else if (enCasa > 0) {
      mensaje = 'Te quedan $enCasa en casa por leer';
      color = AppColors.textSecondary;
    } else {
      mensaje = 'Aún no hay movimiento en la pila este año';
      color = AppColors.textSecondary;
    }
    final maximo = math.max(1, math.max(datos.leidosAnio, enCasa));
    const secundario = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E7D3).withValues(alpha: .55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TU AÑO $anio · LIBROS EN PAPEL',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 10),
          _Barra(
            etiqueta: 'Pendientes en papel leídos o empezados',
            valor: datos.leidosAnio,
            maximo: maximo,
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          _Barra(
            etiqueta: 'En casa sin leer',
            valor: enCasa,
            maximo: maximo,
            color: AppColors.inkCoral,
          ),
          const SizedBox(height: 10),
          Text(
            mensaje,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (datos.leidosEnCasaAnio > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${datos.leidosEnCasaAnio} de los leídos ya los tenías en casa',
                style: secundario,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Libros en papel terminados este año: ${datos.terminadosPapelAnio}',
              style: secundario,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Pendientes en papel nuevos este año: ${datos.entraronAnio}',
              style: secundario,
            ),
          ),
          if (datos.otrosFormatos > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ ${datos.otrosFormatos} en casa en ebook o audiolibro',
                style: secundario,
              ),
            ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.etiqueta,
    required this.valor,
    required this.maximo,
    required this.color,
  });

  final String etiqueta;
  final int valor;
  final int maximo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$valor',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: valor / maximo,
            minHeight: 8,
            backgroundColor: const Color(0xFFE3CFAE).withValues(alpha: .6),
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Aviso para todas: estos datos dependen del formato de cada libro.
class _NotaFormato extends StatelessWidget {
  const _NotaFormato({required this.sinFormato});

  /// Lecturas de este año sin formato apuntado.
  final int sinFormato;

  @override
  Widget build(BuildContext context) {
    final extra = sinFormato > 0
        ? ' Ahora mismo tienes $sinFormato '
              '${sinFormato == 1 ? 'lectura' : 'lecturas'} de este año sin '
              'formato, que se cuentan como papel.'
        : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Solo cuentan los libros en papel o sin formato. Indica el formato '
            'de cada libro (papel, ebook o audiolibro) al terminarlo o desde su '
            'ficha para que las cifras sean fiables.$extra',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
