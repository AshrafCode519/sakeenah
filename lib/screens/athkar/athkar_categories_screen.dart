import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../data/athkar_data.dart';
import 'athkar_reader_screen.dart';

class AthkarCategoriesScreen extends StatelessWidget {
  const AthkarCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      {
        'title': 'أذكار الصباح',
        'subtitle': 'حصن المسلم وبركة يومه، ابدأ يومك بذكر الله',
        'key': 'morning',
        'list': AthkarData.morningAthkar,
        'icon': Icons.wb_sunny_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
      },
      {
        'title': 'أذكار المساء',
        'subtitle': 'حفظ العبد ليلته وسكينة روحه حتى يصبح',
        'key': 'evening',
        'list': AthkarData.eveningAthkar,
        'icon': Icons.nightlight_round,
        'gradient': const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
      },
      {
        'title': 'أذكار بعد الصلاة',
        'subtitle': 'الاستغفار والتسبيح والتحميد بعد الصلوات المكتوبة',
        'key': 'prayer',
        'list': AthkarData.afterPrayerAthkar,
        'icon': Icons.mosque_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857)],
        ),
      },
      {
        'title': 'أذكار النوم والاستيقاظ',
        'subtitle': 'تفويض النفس لله وطلب العافية والوقاية من الشرور',
        'key': 'sleep',
        'list': AthkarData.sleepAthkar,
        'icon': Icons.bedtime_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        ),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('أذكار المسلم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final gradient = cat['gradient'] as LinearGradient;
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.gold.withOpacity(0.2)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AthkarReaderScreen(
                      title: cat['title'] as String,
                      athkarList: cat['list'] as dynamic,
                      categoryKey: cat['key'] as String,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(cat['icon'] as IconData, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                cat['title'] as String,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.goldLight : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                                ),
                                child: Text(
                                  '${ArabicUtils.toArabicDigits((cat['list'] as List).length)} ذِكراً',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat['subtitle'] as String,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gold, size: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
