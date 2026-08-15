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
        showDragHandle: true,
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
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    child: FutureBuilder<ReactionDetails>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _CompactSheet(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _CompactSheet(
            child: Center(
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
            ),
          );
        }
        final details = snapshot.data!;
        if (details.total == 0) {
          return _CompactSheet(
            child: _SheetHeader(
              onRefresh: _retry,
              child: const Center(child: Text('Aún no hay reacciones.')),
            ),
          );
        }
        return _LoadedReactionDetails(details: details, onRefresh: _retry);
      },
    ),
  );
}

class _CompactSheet extends StatelessWidget {
  const _CompactSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    child: SizedBox(
      key: const ValueKey('reaction-sheet-compact'),
      height: _sheetHeight(context, 0, hasTabs: false),
      child: SafeArea(top: false, child: child),
    ),
  );
}

class _LoadedReactionDetails extends StatefulWidget {
  const _LoadedReactionDetails({
    required this.details,
    required this.onRefresh,
  });
  final ReactionDetails details;
  final VoidCallback onRefresh;

  @override
  State<_LoadedReactionDetails> createState() => _LoadedReactionDetailsState();
}

class _LoadedReactionDetailsState extends State<_LoadedReactionDetails>
    with SingleTickerProviderStateMixin {
  late final List<ReactionGroup?> _tabs = [null, ...widget.details.grupos];
  late final TabController _controller = TabController(
    length: _tabs.length,
    vsync: this,
  )..addListener(_tabChanged);
  int _selectedIndex = 0;

  void _tabChanged() {
    if (_controller.index == _selectedIndex) return;
    setState(() {
      _selectedIndex = _controller.index;
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _tabs[_selectedIndex];
    final visibleCount = selected?.usuarios.length ?? widget.details.total;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        key: const ValueKey('reaction-sheet-loaded'),
        height: _sheetHeight(context, visibleCount, hasTabs: true),
        child: SafeArea(
          top: false,
          child: _SheetHeader(
            onRefresh: widget.onRefresh,
            tabs: TabBar(
              controller: _controller,
              isScrollable: true,
              tabs: _tabs
                  .map(
                    (group) => Tab(
                      text: group == null
                          ? 'Todas ${widget.details.total}'
                          : '${_emoji(group.reaccion)} ${group.usuarios.length}',
                    ),
                  )
                  .toList(),
            ),
            child: TabBarView(
              controller: _controller,
              children: _tabs
                  .map(
                    (group) => _ReactionList(
                      users: group?.usuarios ?? widget.details.usuarios,
                      reaction: group?.reaccion,
                      allGroups: widget.details.grupos,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

double _sheetHeight(BuildContext context, int people, {required bool hasTabs}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
  final maxHeight = screenHeight * .68;
  final minHeight = 220.0.clamp(0.0, maxHeight);
  final headerHeight = 64.0 * textScale;
  final tabsHeight = hasTabs ? 48.0 * textScale : 0.0;
  final rowHeight = 64.0 * textScale;
  final desired = headerHeight + tabsHeight + people * rowHeight + bottomInset;
  return desired.clamp(minHeight, maxHeight);
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
