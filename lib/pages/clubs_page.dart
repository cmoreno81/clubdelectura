import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common/onboarding_tutorial.dart';

import '../models/club_membership.dart';
import '../navigation/app_page_route.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/club_context_controller.dart';
import '../services/club_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/perfil/editar_avatar_dialog.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/optimized_network_image.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

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

  void _reload() => setState(() {
    _future = ClubService().getMyClubs();
  });

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

  Future<void> _crearEspacioPersonal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear espacio personal'),
        content: const Text(
          'Tu espacio lector personal te permite llevar tu biblioteca, '
          'reto lector y estadísticas de forma individual, sin compartirlos '
          'con ningún club.\n\n'
          'Todos tus libros actuales estarán disponibles desde el primer momento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear espacio'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await ClubService().crearEspacioPersonal();
    });
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
      if (widget.onboarding) {
        // En el flujo de onboarding, buscar el club activo y volver con él
        // para que ElegirModoPage pueda navegar directamente a HomePage.
        final myClubs = await ClubService().getMyClubs();
        if (!mounted) return;
        final active = myClubs.clubs.where((c) => c.activo).firstOrNull
            ?? (myClubs.activeClubId != null
                ? myClubs.clubs
                    .where((c) => c.id == myClubs.activeClubId)
                    .firstOrNull
                : null);
        Navigator.pop(context, active);
        return;
      }
      _reload();
    } on ApiException catch (error) {
      if (mounted) _snack(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openClubSettings(ClubMembership club) async {
    final changed = await Navigator.push<bool>(
      context,
      AppPageRoute(builder: (_) => _ClubSettingsPage(club: club)),
    );
    if (changed == true) _reload();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
            return const CardListSkeleton();
          }
          final clubs = snapshot.data!.clubs;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100,
            ),
            children: [
              if (clubs.isEmpty) ...[
                const SizedBox(height: 48),
                Icon(
                  Icons.groups_outlined,
                  size: 72,
                  color: AppColors.primary.withValues(alpha: .4),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Crea tu primer club o\nentra con una invitación',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.section,
                ),
                const SizedBox(height: AppSpacing.xl),
              ] else ...[
                for (final club in clubs) ...[
                  _ClubCard(
                    club: club,
                    busy: _busy,
                    onSelect: () => _select(club),
                    onSettings: () => _openClubSettings(club),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.sm),
              ],
              FeatureTooltip(
                featureKey: 'ft_create_club',
                message: 'Crea tu primer club de lectura aquí',
                icon: Icons.group_add_outlined,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _create,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crear un club'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FeatureTooltip(
                featureKey: 'ft_join_club',
                message: 'Únete con el código que te comparten',
                icon: Icons.key_outlined,
                position: FeatureTooltipPosition.above,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _join,
                  icon: const Icon(Icons.key_rounded),
                  label: const Text('Entrar con invitación'),
                ),
              ),
              // Mostrar solo si el usuario NO tiene aún espacio personal
              if (!clubs.any((c) => c.esPersonal)) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _crearEspacioPersonal,
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('Crear mi espacio personal'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({
    required this.club,
    required this.busy,
    required this.onSelect,
    required this.onSettings,
  });

  final ClubMembership club;
  final bool busy;
  final VoidCallback onSelect;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: club.activo,
      gradient: club.activo
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
            )
          : null,
      borderColor: club.activo ? AppColors.primaryLight : AppColors.border,
      onTap: busy ? null : onSelect,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: club.activo ? AppColors.primary : AppColors.border,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: OptimizedNetworkImage(
              url: club.avatarUrl,
              width: 72,
              height: 72,
              fallback: _initials(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.nombre,
                  style: AppTextStyles.section.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (club.descripcion.isNotEmpty)
                  Text(
                    club.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary.copyWith(height: 1.3),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (club.activo) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Activo',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      _rolLabel(club.rol),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ajustes del club',
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined, size: 20),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _initials() => Container(
    color: club.activo ? AppColors.primaryLight : AppColors.surfaceSoft,
    alignment: Alignment.center,
    child: Text(
      club.nombre.isNotEmpty ? club.nombre[0].toUpperCase() : '?',
      style: TextStyle(
        color: club.activo ? AppColors.primary : AppColors.textMuted,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  String _rolLabel(String rol) => switch (rol) {
    'OWNER' => 'Propiedad',
    'ADMIN' => 'Administración',
    _ => 'Miembro',
  };
}

class _ClubSettingsPage extends StatefulWidget {
  const _ClubSettingsPage({required this.club});
  final ClubMembership club;

  @override
  State<_ClubSettingsPage> createState() => _ClubSettingsPageState();
}

class _ClubSettingsPageState extends State<_ClubSettingsPage> {
  late Future<List<ClubMember>> _membersFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _membersFuture = ClubService().getClubMembers(widget.club.id);
  }

  bool get _isAdmin => widget.club.rol == 'OWNER' || widget.club.rol == 'ADMIN';

  Future<void> _copyInvite() async {
    try {
      final code = await ClubService().getInvite(widget.club.id);
      if (code.isEmpty || !mounted) return;
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Código copiado: $code')));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _editClub() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditClubDialog(club: widget.club),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ClubService().updateClub(
        clubId: widget.club.id,
        nombre: result['nombre'],
        descripcion: result['descripcion'],
        avatarUrl: result['avatarUrl'],
      );
      if (!mounted) return;
      Navigator.pop(context, true);
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

  Future<void> _editarFotoClub() async {
    final nuevaUrl = await showDialog<String>(
      context: context,
      builder: (_) =>
          EditarAvatarDialog(avatarUrlActual: widget.club.avatarUrl),
    );
    if (nuevaUrl == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ClubService().updateClub(
        clubId: widget.club.id,
        avatarUrl: nuevaUrl,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
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

  Future<void> _leaveClub() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir del club'),
        content: Text('¿Segura que quieres salir de "${widget.club.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir del club'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ClubService().leaveClub(widget.club.id);
      ClubContextController.instance.refresh();
      if (!mounted) return;
      Navigator.pop(context, true);
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
      appBar: AppBar(title: Text(widget.club.nombre)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          100,
        ),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _busy ? null : _editarFotoClub,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryLight,
                            width: 3,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: OptimizedNetworkImage(
                          url: widget.club.avatarUrl,
                          width: 120,
                          height: 120,
                          fallback: _avatarFallback(widget.club.nombre),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(widget.club.nombre, style: AppTextStyles.section),
                if (widget.club.descripcion.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      widget.club.descripcion,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                if (_isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text(
                      'Código de invitación',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Copia el código para invitar a nuevos miembros',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _busy ? null : _copyInvite,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text(
                      'Editar club',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Nombre, descripción y foto'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _busy ? null : _editClub,
                  ),
                  const Divider(height: 1),
                ],
                FutureBuilder<List<ClubMember>>(
                  future: _membersFuture,
                  builder: (context, snap) {
                    final count = snap.data?.length;
                    return ListTile(
                      leading: const Icon(Icons.people_outline_rounded),
                      title: const Text(
                        'Miembros',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        count != null
                            ? '$count ${count == 1 ? 'persona' : 'personas'} en el club'
                            : 'Ver quién forma parte del club',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push<void>(
                        context,
                        AppPageRoute(
                          builder: (_) => _MembersPage(
                            clubNombre: widget.club.nombre,
                            future: _membersFuture,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (widget.club.rol != 'OWNER') ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.exit_to_app_rounded,
                      color: AppColors.danger,
                    ),
                    title: const Text(
                      'Salir del club',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                    subtitle: const Text('Perderás acceso a lecturas y chats'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.danger,
                    ),
                    onTap: _busy ? null : _leaveClub,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String nombre) => Container(
    color: AppColors.primaryLight,
    alignment: Alignment.center,
    child: Text(
      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MembersPage extends StatelessWidget {
  const _MembersPage({required this.clubNombre, required this.future});
  final String clubNombre;
  final Future<List<ClubMember>> future;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Miembros · $clubNombre')),
      body: FutureBuilder<List<ClubMember>>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const CardListSkeleton();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.md,
            ),
            itemCount: snap.data!.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = snap.data![i];
              return ListTile(
                leading: ClubAvatar(
                  nombre: m.nombre,
                  imageUrl: m.avatarUrl,
                  size: 44,
                ),
                title: Text(
                  m.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(_rolLabel(m.rol)),
                trailing: m.esOwner
                    ? const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.warning,
                        size: 18,
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  String _rolLabel(String rol) => switch (rol) {
    'OWNER' => 'Propiedad',
    'ADMIN' => 'Administración',
    _ => 'Miembro',
  };
}

class _EditClubDialog extends StatefulWidget {
  const _EditClubDialog({required this.club});
  final ClubMembership club;

  @override
  State<_EditClubDialog> createState() => _EditClubDialogState();
}

class _EditClubDialogState extends State<_EditClubDialog> {
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.club.nombre);
    _descripcion = TextEditingController(text: widget.club.descripcion);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar club'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre del club'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descripcion,
              maxLength: 500,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              smartDashesType: SmartDashesType.enabled,
              smartQuotesType: SmartQuotesType.enabled,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_nombre.text.trim().length < 3) return;
            Navigator.pop(context, {
              'nombre': _nombre.text.trim(),
              'descripcion': _descripcion.text.trim(),
            });
          },
          child: const Text('Guardar'),
        ),
      ],
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
            minLines: 2,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            autocorrect: true,
            enableSuggestions: true,
            smartDashesType: SmartDashesType.enabled,
            smartQuotesType: SmartQuotesType.enabled,
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
