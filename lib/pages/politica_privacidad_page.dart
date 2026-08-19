import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class PoliticaPrivacidadPage extends StatelessWidget {
  const PoliticaPrivacidadPage({super.key});

  Future<void> _contactar(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'clubreads.app@gmail.com',
      queryParameters: {'subject': 'Privacidad en ClubReads'},
    );
    final abierto = await launchUrl(uri);
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escríbenos a clubreads.app@gmail.com'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidad')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          48,
        ),
        children: [
          Text(
            'Última actualización: 18 de julio de 2026',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Apartado(
            titulo: 'Responsable',
            texto:
                'ClubReads es una aplicación gestionada por Cristina Moreno para la actividad privada del club de lectura.',
          ),
          const _Apartado(
            titulo: 'Datos que utiliza ClubReads',
            texto:
                'La aplicación guarda los datos necesarios para identificar tu perfil y prestar sus funciones: nombre, correo, avatar, biblioteca, fechas y progreso de lectura, valoraciones, reseñas, comentarios, reacciones y votos de Clubvisión.',
          ),
          const _Apartado(
            titulo: 'Para qué se utilizan',
            texto:
                'Estos datos se utilizan exclusivamente para que el club pueda organizar y compartir su actividad de lectura. ClubReads no vende tus datos ni los utiliza con fines publicitarios.',
          ),
          const _Apartado(
            titulo: 'Almacenamiento y servicios',
            texto:
                'La información se almacena en los servicios técnicos necesarios para el funcionamiento de la aplicación. Las imágenes de perfil y otros recursos pueden alojarse en servicios externos de almacenamiento de imágenes.',
          ),
          const _Apartado(
            titulo: 'Contenido compartido',
            texto:
                'Las demás integrantes del club pueden ver la actividad que publicas dentro de la aplicación, como lecturas, progreso, valoraciones, comentarios y reacciones.',
          ),
          const _Apartado(
            titulo: 'Tus derechos',
            texto:
                'Puedes solicitar información, corrección o eliminación de tus datos. También puedes comunicar cualquier duda relacionada con la privacidad.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _contactar(context),
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Contactar sobre privacidad'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Apartado extends StatelessWidget {
  final String titulo;
  final String texto;

  const _Apartado({required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.xs),
          Text(texto, style: AppTextStyles.bodySecondary.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
