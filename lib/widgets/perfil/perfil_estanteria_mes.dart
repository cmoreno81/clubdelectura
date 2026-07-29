import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/perfil_usuario.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../utils/lectura_fecha_utils.dart';
import '../common/club_book_cover.dart';

class PerfilEstanteriaMes extends StatefulWidget {
  const PerfilEstanteriaMes({
    super.key,
    required this.usuario,
    required this.libros,
    required this.esMiPerfil,
    required this.onBookTap,
  });

  final String usuario;
  final List<PerfilLibroTerminado> libros;
  final bool esMiPerfil;
  final ValueChanged<PerfilLibroTerminado> onBookTap;

  @override
  State<PerfilEstanteriaMes> createState() => _PerfilEstanteriaMesState();
}

class _PerfilEstanteriaMesState extends State<PerfilEstanteriaMes> {
  bool _ready = false;
  bool _animateLatest = false;
  bool _landed = false;

  List<PerfilLibroTerminado> get _monthBooks {
    final now = DateTime.now();
    final books = widget.libros.where((book) {
      final finishedAt = LecturaFechaUtils.parse(book.fechaFin);
      return finishedAt?.year == now.year && finishedAt?.month == now.month;
    }).toList();
    books.sort((left, right) {
      final leftDate = LecturaFechaUtils.parse(left.fechaFin) ?? DateTime(1900);
      final rightDate =
          LecturaFechaUtils.parse(right.fechaFin) ?? DateTime(1900);
      return leftDate.compareTo(rightDate);
    });
    return books;
  }

  @override
  void initState() {
    super.initState();
    _prepareAnimation();
  }

  @override
  void didUpdateWidget(covariant PerfilEstanteriaMes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_latestIdentity(oldWidget.libros) != _latestIdentity(widget.libros)) {
      _ready = false;
      _landed = false;
      _animateLatest = false;
      _prepareAnimation();
    }
  }

  String _latestIdentity(List<PerfilLibroTerminado> source) {
    if (source.isEmpty) return '';
    final sorted = [...source]
      ..sort((left, right) {
        final leftDate =
            LecturaFechaUtils.parse(left.fechaFin) ?? DateTime(1900);
        final rightDate =
            LecturaFechaUtils.parse(right.fechaFin) ?? DateTime(1900);
        return leftDate.compareTo(rightDate);
      });
    final latest = sorted.last;
    return latest.completionId.trim().isNotEmpty
        ? latest.completionId.trim()
        : '${latest.bookId}:${latest.fechaFin}:${latest.libro}';
  }

  Future<void> _prepareAnimation() async {
    final books = _monthBooks;
    if (!widget.esMiPerfil || books.isEmpty) {
      if (mounted) setState(() => _ready = true);
      return;
    }

    final latest = books.last;
    final latestKey = latest.completionId.trim().isNotEmpty
        ? latest.completionId.trim()
        : '${latest.bookId}:${latest.fechaFin}:${latest.libro}';
    final safeUser = widget.usuario.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    final preferenceKey = 'monthly_shelf_latest_$safeUser';
    final preferences = await SharedPreferences.getInstance();
    final shouldAnimate = preferences.getString(preferenceKey) != latestKey;
    if (shouldAnimate) {
      await preferences.setString(preferenceKey, latestKey);
    }
    if (!mounted) return;

    setState(() {
      _ready = true;
      _animateLatest = shouldAnimate;
    });
    if (shouldAnimate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _landed = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = _monthBooks;
    final month = _monthName(DateTime.now().month);

    return Semantics(
      label: 'Estantería de $month, ${books.length} libros terminados',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4E7D3),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: const Color(0xFFD3B58E)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF65452F).withValues(alpha: .10),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.shelves,
                    color: AppColors.primaryDark,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mi estantería de $month',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${books.length} ${books.length == 1 ? 'libro' : 'libros'}',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (!_ready)
              const SizedBox(
                height: 172,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (books.isEmpty)
              const SizedBox(height: 172, child: _EmptyShelf())
            else
              for (var start = 0; start < books.length; start += 4)
                _ShelfRow(
                  books: books.sublist(
                    start,
                    start + 4 < books.length ? start + 4 : books.length,
                  ),
                  animatedBook:
                      _animateLatest &&
                          start <= books.length - 1 &&
                          books.length - 1 < start + 4
                      ? books.last
                      : null,
                  landed: _landed,
                  onBookTap: widget.onBookTap,
                ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) => const [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ][month - 1];
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({
    required this.books,
    required this.animatedBook,
    required this.landed,
    required this.onBookTap,
  });

  final List<PerfilLibroTerminado> books;
  final PerfilLibroTerminado? animatedBook;
  final bool landed;
  final ValueChanged<PerfilLibroTerminado> onBookTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8D4B7), Color(0xFFF8EEDD)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const _WoodGrain())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Container(
              height: 18,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFB9834F),
                    Color(0xFF8A5937),
                    Color(0xFF68422E),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55351F14),
                    blurRadius: 7,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            bottom: 30,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 10, 17, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < books.length; index++) ...[
                    if (index > 0) const SizedBox(width: 10),
                    Builder(
                      builder: (context) {
                        final book = books[index];
                        final animate = identical(book, animatedBook);
                        final cover = ClubBookCover(
                          title: book.libro,
                          imageUrl: book.coverUrl,
                          width: 67,
                          height: 104,
                          borderRadius: BorderRadius.circular(5),
                          onTap: () => onBookTap(book),
                        );
                        if (!animate) {
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: cover,
                          );
                        }

                        return AnimatedSlide(
                          offset: landed ? Offset.zero : const Offset(0, -1.25),
                          duration: const Duration(milliseconds: 850),
                          curve: Curves.bounceOut,
                          child: AnimatedRotation(
                            turns: landed ? 0 : -.035,
                            duration: const Duration(milliseconds: 850),
                            curve: Curves.easeOutBack,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: const _WoodGrain())),
        const Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(28, 8, 28, 35),
            child: Text(
              'Tu próxima lectura terminada ocupará el primer hueco.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: Container(height: 18, color: const Color(0xFF8A5937)),
        ),
      ],
    );
  }
}

class _WoodGrain extends CustomPainter {
  const _WoodGrain();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7F5839).withValues(alpha: .075)
      ..strokeWidth = .8;
    for (double y = 9; y < size.height; y += 15) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        path.quadraticBezierTo(x + 12, y + 3, x + 24, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
