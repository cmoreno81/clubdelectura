import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

class ClubAvatar extends StatelessWidget {
  final String nombre;
  final String? imageUrl;
  final double size;
  final bool online;
  final VoidCallback? onTap;

  const ClubAvatar({
    super.key,
    required this.nombre,
    this.imageUrl,
    this.size = 52,
    this.online = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(imageUrl!, fit: BoxFit.cover)
            : Center(
                child: Text(
                  _iniciales(nombre),
                  style: AppTextStyles.section.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (onTap != null)
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onTap,
            child: avatar,
          )
        else
          avatar,

        if (online)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: size * .24,
              height: size * .24,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  String _iniciales(String texto) {
    final partes = texto
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (partes.isEmpty) return "?";

    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }

    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}
