import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/common/club_reads_mark.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ClubReadsMark(size: 72),
            const SizedBox(height: 18),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Club',
                    style: GoogleFonts.dmSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: 'Reads',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'LEE · COMENTA · COMPARTE',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                letterSpacing: 1.6,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
