import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';

class TecnologiaCreditosPage extends StatelessWidget {
  const TecnologiaCreditosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tecnología y créditos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          48,
        ),
        children: const [
          ClubCard(
            elevated: false,
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Creado y cuidado por Cristina Moreno',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Diseño, desarrollo y evolución de ClubReads.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          _GrupoTecnologia(
            icon: Icons.phone_iphone_rounded,
            titulo: 'Aplicación móvil',
            tecnologias: [
              _Tecnologia(
                'Flutter',
                'Interfaz multiplataforma para iOS y Android',
              ),
              _Tecnologia('Dart', 'Lenguaje de la aplicación'),
              _Tecnologia('Material Design', 'Componentes y sistema visual'),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _GrupoTecnologia(
            icon: Icons.dns_outlined,
            titulo: 'Servidor',
            tecnologias: [
              _Tecnologia('Node.js', 'Entorno de ejecución del backend'),
              _Tecnologia('TypeScript', 'Código tipado del servidor'),
              _Tecnologia('Express', 'API y rutas de ClubReads'),
              _Tecnologia('Zod', 'Validación de datos'),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _GrupoTecnologia(
            icon: Icons.storage_rounded,
            titulo: 'Datos',
            tecnologias: [
              _Tecnologia('PostgreSQL', 'Base de datos relacional'),
              _Tecnologia('Prisma ORM', 'Modelos, consultas y migraciones'),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _GrupoTecnologia(
            icon: Icons.cloud_outlined,
            titulo: 'Infraestructura',
            tecnologias: [
              _Tecnologia(
                'Railway',
                'Despliegue del backend, base de datos y tareas programadas',
              ),
              _Tecnologia(
                'Cloudinary',
                'Almacenamiento y tratamiento de imágenes',
              ),
              _Tecnologia(
                'Git y GitHub',
                'Control de versiones y conexión de despliegues',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _GrupoTecnologia(
            icon: Icons.extension_outlined,
            titulo: 'Funciones del dispositivo',
            tecnologias: [
              _Tecnologia('HTTP y Dio', 'Comunicación segura con la API'),
              _Tecnologia('Shared Preferences', 'Preferencias locales'),
              _Tecnologia('Image Picker', 'Selección de imágenes'),
              _Tecnologia('Image', 'Procesamiento de imágenes'),
              _Tecnologia('Palette Generator', 'Colores extraídos de portadas'),
              _Tecnologia('Share Plus', 'Contenido compartido desde el móvil'),
              _Tecnologia('URL Launcher', 'Correo y enlaces externos'),
              _Tecnologia('Package Info', 'Versión instalada de la aplicación'),
              _Tecnologia('Path Provider', 'Acceso a archivos temporales'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrupoTecnologia extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final List<_Tecnologia> tecnologias;

  const _GrupoTecnologia({
    required this.icon,
    required this.titulo,
    required this.tecnologias,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(titulo, style: AppTextStyles.subtitle),
              ],
            ),
          ),
          for (var index = 0; index < tecnologias.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            ListTile(
              title: Text(tecnologias[index].nombre),
              subtitle: Text(tecnologias[index].descripcion),
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _Tecnologia {
  final String nombre;
  final String descripcion;

  const _Tecnologia(this.nombre, this.descripcion);
}
