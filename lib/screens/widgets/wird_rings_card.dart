import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_numbers.dart';

class WirdRingsCard extends StatelessWidget {
  final bool morningDone;
  final bool eveningDone;
  final int quranPages;
  final int tasbihCount;
  final VoidCallback? onRefresh;

  const WirdRingsCard({
    super.key,
    required this.morningDone,
    required this.eveningDone,
    required this.quranPages,
    required this.tasbihCount,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate total score: Morning (25%), Evening (25%), Quran pages (25% for 4 pages), Tasbih (25% for 100)
    double progress = 0;
    if (morningDone) progress += 0.25;
    if (eveningDone) progress += 0.25;
    progress += (quranPages / 4).clamp(0.0, 1.0) * 0.25;
    progress += (tasbihCount / 100).clamp(0.0, 1.0) * 0.25;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.incomplete_circle_rounded, color: AppColors.gold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'حلقات الورد اليومي',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldLight : AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(
                  '${(progress * 100).round()}% مكتمل',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4 Ring Items in a Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWirdItem(
                context,
                title: 'أذكار الصباح',
                isDone: morningDone,
                icon: Icons.wb_sunny_rounded,
                color: Colors.amber,
              ),
              _buildWirdItem(
                context,
                title: 'أذكار المساء',
                isDone: eveningDone,
                icon: Icons.nightlight_round,
                color: Colors.indigoAccent,
              ),
              _buildWirdItem(
                context,
                title: 'ورد القرآن',
                subtitle: '${ArabicUtils.toArabicDigits(quranPages)} / ٤ ص',
                isDone: quranPages >= 4,
                icon: Icons.menu_book_rounded,
                color: AppColors.primaryAccent,
              ),
              _buildWirdItem(
                context,
                title: 'التسبيح',
                subtitle: '${ArabicUtils.toArabicDigits(tasbihCount)} / ١٠٠',
                isDone: tasbihCount >= 100,
                icon: Icons.fingerprint_rounded,
                color: AppColors.gold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWirdItem(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool isDone,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: isDone ? 1.0 : (subtitle != null ? 0.4 : 0.0),
                strokeWidth: 3.5,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? AppColors.success : color,
                ),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDone ? AppColors.success : color).withOpacity(0.15),
              ),
              child: Icon(
                isDone ? Icons.check_rounded : icon,
                size: 20,
                color: isDone ? AppColors.success : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textDark,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}
