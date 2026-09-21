import 'dart:async';

import 'package:flutter/material.dart';

import '../models/club_directory.dart';
import '../services/api_exception.dart';
import '../services/club_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/error_view.dart';

/// Directorio de clubes públicos: buscar y solicitar unirse sin código de
/// invitación. La solicitud queda pendiente hasta que la admin del club la
/// acepta o la rechaza.
class ClubDirectorioPage extends StatefulWidget {
  const ClubDirectorioPage({super.key});

  @override
  State<ClubDirectorioPage> createState() => _ClubDirectorioPageState();
}

class _ClubDirectorioPageState extends State<ClubDirectorioPage> {
  late Future<List<ClubPublico>> _future;
  final _searchController = TextEditingController();
  Timer? _debounce;
  final Set<String> _solicitados = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = ClubService().getClubesPublicos();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _future = ClubService().getClubesPublicos(search: value);
      });
    });
  }

  Future<void> _solicitar(ClubPublico club) async {
    setState(() => _busy = true);
    try {
      await ClubService().solicitarUnirseClub(club.clubId);
      if (!mounted) return;
      setState(() => _solicitados.add(club.clubId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solicitud enviada a ${club.nombre}. Te avisaremos cuando la respondan.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clubes públicos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar un club por nombre…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ClubPublico>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    onRetry: () => setState(() {
                      _future = ClubService().getClubesPublicos(
                        search: _searchController.text,
                      );
                    }),
                  );
                }
                final clubes = snapshot.data ?? const [];
                if (clubes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        _searchController.text.trim().isEmpty
                            ? 'Todavía no hay clubes públicos.'
                            : 'No hay clubes públicos que coincidan con tu búsqueda.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    40,
                  ),
                  itemCount: clubes.length,
                  itemBuilder: (context, index) {
                    final club = clubes[index];
                    final yaSolicitado = _solicitados.contains(club.clubId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            ClubAvatar(
                              nombre: club.nombre,
                              imageUrl: club.avatarUrl,
                              size: 48,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    club.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if ((club.descripcion ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      club.descripcion!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySecondary,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${club.miembros} ${club.miembros == 1 ? 'miembro' : 'miembros'}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            if (yaSolicitado)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: Text('Pendiente'),
                              )
                            else
                              OutlinedButton(
                                onPressed: _busy ? null : () => _solicitar(club),
                                child: const Text('Solicitar'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
