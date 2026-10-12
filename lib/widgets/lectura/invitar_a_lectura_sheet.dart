import 'package:flutter/material.dart';

import '../../models/club_membership.dart';
import '../../services/api_service.dart';
import '../../services/auth_session_service.dart';
import '../../services/club_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Hoja para invitar a miembros del propio club a una lectura conjunta.
/// Solo se puede invitar a gente del club; les llega un aviso amistoso.
Future<void> mostrarInvitarALectura(BuildContext context, String libro) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _InvitarSheet(libro: libro),
  );
}

class _InvitarSheet extends StatefulWidget {
  const _InvitarSheet({required this.libro});

  final String libro;

  @override
  State<_InvitarSheet> createState() => _InvitarSheetState();
}

class _InvitarSheetState extends State<_InvitarSheet> {
  late final Future<List<ClubMember>> _miembros = _cargar();
  final Set<String> _elegidas = {};
  bool _enviando = false;

  Future<List<ClubMember>> _cargar() async {
    final servicio = ClubService();
    final clubs = await servicio.getMyClubs();
    final id = clubs.activeClubId;
    if (id == null || id.isEmpty) return const [];
    final yo = AuthSessionService.instance.user?.id;
    final lista = await servicio.getClubMembers(id);
    return lista.where((m) => m.id != yo).toList(growable: false);
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final enviadas = await ApiService().invitarALectura(
      libro: widget.libro,
      usuarios: _elegidas.toList(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    final mensaje = enviadas == null
        ? 'No se han podido enviar las invitaciones. Inténtalo de nuevo.'
        : enviadas == 0
        ? 'Ya la están leyendo o ya las habías invitado 💜'
        : enviadas == 1
        ? 'Invitación enviada 💌'
        : '$enviadas invitaciones enviadas 💌';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitar a la lectura',
              style: AppTextStyles.body.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Elige a quién del club quieres avisar de "${widget.libro}".',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: FutureBuilder<List<ClubMember>>(
                future: _miembros,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final lista = snapshot.data ?? const <ClubMember>[];
                  if (lista.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Aún no hay más personas en el club.',
                        style: AppTextStyles.bodySecondary,
                      ),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final m in lista)
                        CheckboxListTile(
                          value: _elegidas.contains(m.id),
                          title: Text(m.nombre),
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: _enviando
                              ? null
                              : (v) => setState(() {
                                  v == true
                                      ? _elegidas.add(m.id)
                                      : _elegidas.remove(m.id);
                                }),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _elegidas.isEmpty || _enviando ? null : _enviar,
              icon: const Icon(Icons.send_rounded),
              label: Text(
                _enviando
                    ? 'Enviando...'
                    : _elegidas.length > 1
                    ? 'Invitar a ${_elegidas.length} personas'
                    : 'Invitar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
