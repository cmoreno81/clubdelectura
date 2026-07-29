import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/club_membership.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/club_context_controller.dart';
import '../services/club_service.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({
    super.key,
    this.clubs,
    this.onboarding = false,
    this.onChanged,
  });

  final MyClubs? clubs;
  final bool onboarding;
  final VoidCallback? onChanged;

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  late Future<MyClubs> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.clubs == null
        ? ClubService().getMyClubs()
        : Future.value(widget.clubs);
  }

  void _reload() {
    setState(() {
      _future = ClubService().getMyClubs();
    });
  }

  Future<void> _select(ClubMembership club) async {
    if (club.activo || _busy) return;
    await _run(() => ClubService().selectClub(club.id));
  }

  Future<void> _create() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _CreateClubDialog(),
    );
    if (result == null) return;
    await _run(
      () => ClubService().createClub(
        nombre: result['nombre'] ?? '',
        descripcion: result['descripcion'] ?? '',
      ),
    );
  }

  Future<void> _join() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _JoinClubDialog(),
    );
    if (code == null) return;
    await _run(() => ClubService().joinClub(code));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (widget.onChanged != null) {
        widget.onChanged!.call();
      } else {
        ClubContextController.instance.refresh();
      }
      if (widget.onboarding) return;
      _reload();
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(ClubMembership club) async {
    try {
      final code = await ClubService().getInvite(club.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invitación al club'),
          content: SelectableText(
            code,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Copiar código'),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.onboarding,
        title: Text(widget.onboarding ? 'Tu espacio de lectura' : 'Mis clubes'),
        actions: widget.onboarding
            ? [
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: () => AuthService().logout(),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ]
            : null,
      ),
      body: FutureBuilder<MyClubs>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final clubs = snapshot.data!.clubs;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (clubs.isEmpty) ...[
                Icon(
                  Icons.groups_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Crea tu primer club o entra con una invitación',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 28),
              ] else
                ...clubs.map(
                  (club) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          club.nombre.isEmpty
                              ? '?'
                              : club.nombre[0].toUpperCase(),
                        ),
                      ),
                      title: Text(club.nombre),
                      subtitle: Text(
                        club.activo ? '${club.rol} · Activo' : club.rol,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (club.rol == 'OWNER' || club.rol == 'ADMIN')
                            IconButton(
                              tooltip: 'Invitar',
                              onPressed: () => _invite(club),
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                            ),
                          if (club.activo)
                            const Icon(Icons.check_circle_rounded)
                          else
                            const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: () => _select(club),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear un club'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _join,
                icon: const Icon(Icons.key_rounded),
                label: const Text('Entrar con invitación'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreateClubDialog extends StatefulWidget {
  const _CreateClubDialog();

  @override
  State<_CreateClubDialog> createState() => _CreateClubDialogState();
}

class _CreateClubDialogState extends State<_CreateClubDialog> {
  final name = TextEditingController();
  final description = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear un club'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre del club'),
          ),
          TextField(
            controller: description,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final value = name.text.trim();
            if (value.length < 3) return;
            Navigator.pop(context, {
              'nombre': value,
              'descripcion': description.text,
            });
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _JoinClubDialog extends StatefulWidget {
  const _JoinClubDialog();

  @override
  State<_JoinClubDialog> createState() => _JoinClubDialogState();
}

class _JoinClubDialogState extends State<_JoinClubDialog> {
  final code = TextEditingController();
  String? pasteMessage;

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (value.isEmpty) {
      setState(() => pasteMessage = 'No hay ningún código en el portapapeles');
      return;
    }
    setState(() {
      code.text = value;
      code.selection = TextSelection.collapsed(offset: value.length);
      pasteMessage = 'Código pegado';
    });
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entrar en un club'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Código de invitación',
              suffixIcon: IconButton(
                tooltip: 'Pegar código',
                onPressed: _pasteCode,
                icon: const Icon(Icons.content_paste_rounded),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pasteCode,
            icon: const Icon(Icons.content_paste_go_rounded),
            label: const Text('Pegar código'),
          ),
          if (pasteMessage != null)
            Text(
              pasteMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (code.text.trim().isEmpty) return;
            Navigator.pop(context, code.text.trim());
          },
          child: const Text('Entrar'),
        ),
      ],
    );
  }
}
