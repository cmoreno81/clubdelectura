import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/estanteria_pendientes.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/comprar_libros_page.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// "Tu pila de pendientes": un contador con lo que sube o baja cada mes, el
/// balance del año (pendientes leídos frente a nuevos) y la línea de cómo
/// evoluciona la pila. En el perfil de otra lectora del club ([usuario]) se
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
          _BalanceAnual(datos: d),
          const SizedBox(height: 16),
          _EnCasa(datos: d),
          if (d.hayHistorial) ...[
            const SizedBox(height: 18),
            const Text(
              'Evolución de los últimos 12 meses',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            _LineaPila(serie: d.serie),
          ],
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
class _BalanceAnual extends StatelessWidget {
  const _BalanceAnual({required this.datos});

  final EstanteriaPendientes datos;

  @override
  Widget build(BuildContext context) {
    final balance = datos.balanceAnio;
    final anio = datos.anio == 0 ? DateTime.now().year : datos.anio;
    final String mensaje;
    final Color color;
    if (datos.leidosAnio == 0 && datos.entraronAnio == 0) {
      mensaje = 'Aún no hay movimiento en la pila este año';
      color = AppColors.textSecondary;
    } else if (balance > 0) {
      mensaje = 'Vas ganando: la pila baja $balance en $anio';
      color = AppColors.success;
    } else if (balance < 0) {
      mensaje = 'La pila ha crecido ${-balance} en $anio';
      color = AppColors.inkCoral;
    } else {
      mensaje = 'En $anio entra lo mismo que sale';
      color = AppColors.textSecondary;
    }
    final maximo = math.max(1, math.max(datos.leidosAnio, datos.entraronAnio));
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
            etiqueta: 'Pendientes en papel nuevos',
            valor: datos.entraronAnio,
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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

/// Fila discreta con cuántos pendientes ya están en casa.
class _EnCasa extends StatelessWidget {
  const _EnCasa({required this.datos});

  final EstanteriaPendientes datos;

  @override
  Widget build(BuildContext context) {
    final extra = datos.otrosFormatos > 0
        ? ' (${datos.otrosFormatos} en ebook o audiolibro)'
        : '';
    return Row(
      children: [
        const Icon(Icons.home_outlined, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'En casa sin leer: ${datos.tengo} de ${datos.pendientes}$extra',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Línea con los pendientes al final de cada mes (último punto = hoy).
class _LineaPila extends StatelessWidget {
  const _LineaPila({required this.serie});

  final List<PuntoPila> serie;

  static const _meses = [
    'E',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];

  @override
  Widget build(BuildContext context) {
    final valores = [for (final p in serie) p.pila];
    String inicialMes(PuntoPila p) {
      final m = int.tryParse(p.mes.length >= 7 ? p.mes.substring(5, 7) : '');
      return m == null ? '' : _meses[(m - 1).clamp(0, 11)];
    }

    return Column(
      children: [
        SizedBox(
          height: 90,
          width: double.infinity,
          child: CustomPaint(painter: _PintorLinea(valores)),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final p in serie)
              Text(
                inicialMes(p),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PintorLinea extends CustomPainter {
  _PintorLinea(this.valores);

  final List<int> valores;

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.length < 2) return;
    final maximo = valores.reduce(math.max);
    final minimo = valores.reduce(math.min);
    final rango = math.max(1, maximo - minimo);
    final paso = size.width / (valores.length - 1);
    Offset punto(int i) => Offset(
      i * paso,
      size.height - 8 - ((valores[i] - minimo) / rango) * (size.height - 16),
    );
    // Rejilla fina en el máximo, el mínimo y el punto medio.
    final rejilla = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (final f in [0.0, .5, 1.0]) {
      final y = 8 + f * (size.height - 16);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rejilla);
    }
    final linea = Path()..moveTo(punto(0).dx, punto(0).dy);
    for (var i = 1; i < valores.length; i++) {
      linea.lineTo(punto(i).dx, punto(i).dy);
    }
    final area = Path.from(linea)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AppColors.primary.withValues(alpha: .12),
    );
    canvas.drawPath(
      linea,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    final fin = punto(valores.length - 1);
    canvas.drawCircle(fin, 5, Paint()..color = AppColors.surface);
    canvas.drawCircle(fin, 3.5, Paint()..color = AppColors.inkCoral);
    // Etiquetas del máximo y del actual.
    void etiqueta(String t, Offset o, {bool izquierda = false}) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(izquierda ? o.dx : o.dx - tp.width, o.dy));
    }

    etiqueta('$maximo', const Offset(2, -1), izquierda: true);
    etiqueta('$minimo', Offset(2, size.height - 12), izquierda: true);
  }

  @override
  bool shouldRepaint(covariant _PintorLinea old) => old.valores != valores;
}
