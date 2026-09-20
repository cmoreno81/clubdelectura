import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/error_view.dart';

class UsuariasBloqueadasPage extends StatefulWidget {
  const UsuariasBloqueadasPage({super.key});

  @override
  State<UsuariasBloqueadasPage> createState() =>
      _UsuariasBloqueadasPageState();
}

class _UsuariasBloqueadasPageState extends State<UsuariasBloqueadasPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().usuariosBloqueados();
  }

  void _recargar() => setState(() {
    _future = ApiService().usuariosBloqueados();
  });

  Future<void> _desbloquear(String nombre) async {
    final ok = await ApiService().desbloquearUsuario(nombre: nombre);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Has desbloqueado a $nombre.')));
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarias bloqueadas')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }
          final bloqueadas = snapshot.data ?? const [];
          if (bloqueadas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No has bloqueado a nadie.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: bloqueadas.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final u = bloqueadas[i];
              final nombre = u['nombre']?.toString() ?? '';
              final avatarUrl = u['avatarUrl']?.toString() ?? '';
              return ClubCard(
                elevated: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    ClubAvatar(nombre: nombre, imageUrl: avatarUrl, size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _desbloquear(nombre),
                      child: const Text('Desbloquear'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
