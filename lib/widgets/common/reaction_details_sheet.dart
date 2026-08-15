import 'package:flutter/material.dart';

import '../../models/reaccion_comentario.dart';
import '../../models/reaction_details.dart';
import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'club_avatar.dart';

typedef ReactionDetailsLoader = Future<ReactionDetails> Function();

class ReactionDetailsSheet extends StatefulWidget {
  const ReactionDetailsSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    this.loader,
  });

  final String targetType;
  final String targetId;
  final ReactionDetailsLoader? loader;

  static final Set<String> _openTargets = <String>{};

  static Future<void> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
  }) async {
    final key = '$targetType:$targetId';
    if (targetId.isEmpty || !_openTargets.add(key)) return;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) =>
            ReactionDetailsSheet(targetType: targetType, targetId: targetId),
      );
    } finally {
      _openTargets.remove(key);
    }
  }

  @override
  State<ReactionDetailsSheet> createState() => _ReactionDetailsSheetState();
}

class _ReactionDetailsSheetState extends State<ReactionDetailsSheet> {
  late Future<ReactionDetails> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future =
        widget.loader?.call() ??
        ApiService().getReactionDetails(
          targetType: widget.targetType,
          targetId: widget.targetId,
        );
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .68,
    child: FutureBuilder<ReactionDetails>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se han podido cargar las reacciones.'),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final details = snapshot.data!;
        if (details.total == 0) {
          return _SheetHeader(
            onRefresh: _retry,
            child: const Center(child: Text('Aún no hay reacciones.')),
          );
        }
        final tabs = <ReactionGroup?>[null, ...details.grupos];
        return DefaultTabController(
          length: tabs.length,
          child: _SheetHeader(
            onRefresh: _retry,
            tabs: TabBar(
              isScrollable: true,
              tabs: tabs
                  .map(
                    (group) => Tab(
                      text: group == null
                          ? 'Todas ${details.total}'
                          : '${_emoji(group.reaccion)} ${group.usuarios.length}',
                    ),
                  )
                  .toList(),
            ),
            child: TabBarView(
              children: tabs
                  .map(
                    (group) => _ReactionList(
                      users: group?.usuarios ?? details.usuarios,
                      reaction: group?.reaccion,
                      allGroups: details.grupos,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onRefresh, required this.child, this.tabs});
  final VoidCallback onRefresh;
  final Widget child;
  final Widget? tabs;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        title: Text('Reacciones', style: AppTextStyles.section),
        trailing: IconButton(
          tooltip: 'Actualizar reacciones',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
      ?tabs,
      Expanded(child: child),
    ],
  );
}

class _ReactionList extends StatelessWidget {
  const _ReactionList({
    required this.users,
    required this.allGroups,
    this.reaction,
  });
  final List<ReactionUser> users;
  final List<ReactionGroup> allGroups;
  final String? reaction;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    itemCount: users.length,
    itemBuilder: (context, index) {
      final user = users[index];
      final type =
          reaction ??
          allGroups
              .firstWhere(
                (group) => group.usuarios.any((item) => item.id == user.id),
              )
              .reaccion;
      return ListTile(
        leading: ClubAvatar(
          nombre: user.nombre,
          imageUrl: user.avatarUrl,
          size: 40,
        ),
        title: Text(user.esTu ? 'Tú' : user.nombre),
        trailing: Text(_emoji(type), style: const TextStyle(fontSize: 24)),
      );
    },
  );
}

String _emoji(String value) =>
    ReaccionComentarioDatos.fromApi(value)?.emoji ?? '•';
