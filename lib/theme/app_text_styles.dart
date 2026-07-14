import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const hero = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.15,
  );

  static const title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const section = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const bodySecondary = TextStyle(
    fontSize: 15,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(fontSize: 13, color: AppColors.textMuted);

  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}
