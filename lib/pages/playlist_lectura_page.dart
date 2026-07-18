import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/playlist_lectura_seleccion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';

class PlaylistLecturaPage extends StatelessWidget {
  final String libro;
  final String atmosferaId;
  final String musicaSugerida;

  const PlaylistLecturaPage({
    super.key,
    required this.libro,
    required this.atmosferaId,
    required this.musicaSugerida,
  });

  String get _mood {
    if (musicaSugerida.trim().isNotEmpty) return musicaSugerida.trim();
    return switch (atmosferaId.toUpperCase()) {
      'OSCURA' || 'GOTICA' => 'dark academia instrumental',
      'ROMANTICA' => 'romantic reading instrumental',
      'BOSQUE' => 'enchanted forest ambience',
      'MARINA' => 'ocean reading ambience',
      'EPICA' => 'epic fantasy reading soundtrack',
      'FUTURISTA' => 'sci fi ambient reading',
      'ACOGEDORA' => 'cozy reading jazz',
      'HISTORICA' => 'historical classical ambience',
      'MISTERIOSA' => 'mystery ambience instrumental',
      _ => 'fantasy reading ambience',
    };
  }

  List<_PlaylistOption> get _opciones => [
    _PlaylistOption(
      titulo: 'Banda sonora del libro',
      descripcion: _mood,
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFFD85D88),
      query: '$libro $_mood playlist',
    ),
    _PlaylistOption(
      titulo: 'Sesión instrumental',
      descripcion: 'Sin letra, pensada para leer sin distracciones',
      icon: Icons.headphones_rounded,
      color: const Color(0xFF6656A8),
      query: '$_mood instrumental reading focus',
    ),
    _PlaylistOption(
      titulo: 'Ambiente inmersivo',
      descripcion: 'Paisajes sonoros largos para entrar en la historia',
      icon: Icons.graphic_eq_rounded,
      color: const Color(0xFF3F8290),
      query: '$_mood ambience 3 hours',
    ),
  ];

  Future<void> _abrir(
    BuildContext context,
    _PlaylistOption option,
    bool spotify,
  ) async {
    final encoded = Uri.encodeComponent(option.query);
    final uri = Uri.parse(
      spotify
          ? 'https://open.spotify.com/search/$encoded'
          : 'https://music.youtube.com/search?q=$encoded',
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la plataforma.')),
      );
      return;
    }

    Navigator.pop(
      context,
      PlaylistLecturaSeleccion(titulo: option.titulo, url: uri.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist lectora')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          48,
        ),
        children: [
          ClubCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.xl),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0F5), Color(0xFFF1EAFF)],
            ),
            borderColor: const Color(0xFFEBC4D5),
            child: Column(
              children: [
                const Icon(
                  Icons.library_music_rounded,
                  size: 52,
                  color: Color(0xFFD85D88),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  libro,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(fontSize: 27),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Elige cómo quieres que suene tu próxima sesión de lectura.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final option in _opciones) ...[
            _PlaylistCard(
              option: option,
              onSpotify: () => _abrir(context, option, true),
              onYouTube: () => _abrir(context, option, false),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _PlaylistOption {
  final String titulo;
  final String descripcion;
  final IconData icon;
  final Color color;
  final String query;

  const _PlaylistOption({
    required this.titulo,
    required this.descripcion,
    required this.icon,
    required this.color,
    required this.query,
  });
}

class _PlaylistCard extends StatelessWidget {
  final _PlaylistOption option;
  final VoidCallback onSpotify;
  final VoidCallback onYouTube;

  const _PlaylistCard({
    required this.option,
    required this.onSpotify,
    required this.onYouTube,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: option.color.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(option.icon, color: option.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.titulo, style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      option.descripcion,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSpotify,
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: const Text('Spotify'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF178A49),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onYouTube,
                  icon: const Icon(Icons.smart_display_rounded),
                  label: const Text('YouTube'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
