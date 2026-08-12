import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Sistema tipográfico de ClubReads.
///
/// Tres familias con roles claros:
///   · Playfair Display — headings (hero, title, section): editorial, "portada de libro"
///   · Lora            — cuerpo de texto (body, bodySecondary): diseñado para leer en pantalla
///   · DM Sans         — chrome de UI (subtitle, caption, button): limpio y moderno
abstract final class AppTextStyles {
  // ── Playfair Display — headings ─────────────────────────────────────────────

  static final hero = GoogleFonts.playfairDisplay(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.15,
  );

  static final title = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static final section = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  // ── DM Sans — chrome de interfaz ────────────────────────────────────────────

  static final subtitle = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static final button = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static final caption = GoogleFonts.dmSans(
    fontSize: 13,
    color: AppColors.textMuted,
    letterSpacing: 0.15,
  );

  // ── Lora — cuerpo de texto ───────────────────────────────────────────────────

  static final body = GoogleFonts.lora(
    fontSize: 16,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static final bodySecondary = GoogleFonts.lora(
    fontSize: 15,
    height: 1.5,
    color: AppColors.textSecondary,
  );
}
