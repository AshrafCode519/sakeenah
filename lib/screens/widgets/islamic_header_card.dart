import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/islamic_patterns.dart';
import '../../core/services/prayer_times_service.dart';
import '../../models/location_model.dart';
import '../../data/quran_data.dart';

class IslamicHeaderCard extends StatelessWidget {
  final VoidCallback? onAyahTap;
  final VoidCallback? onBookmarkResume;
  final int bookmarkSurahNumber;
  final int bookmarkAyahNumber;
  final LocationModel? location;

  const IslamicHeaderCard({
    super.key,
    this.onAyahTap,
    this.onBookmarkResume,
    this.bookmarkSurahNumber = 1,
    this.bookmarkAyahNumber = 1,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hijriDate = PrayerTimesService.getApproximateHijriDate(now);
    final prayers = PrayerTimesService.getTodayPrayerTimes(location: location, date: now);
    final nextPrayer = prayers.firstWhere((p) => p.isNext, orElse: () => prayers.first);

    final surahName = QuranData.allSurahs.firstWhere(
      (s) => s.number == bookmarkSurahNumber,
      orElse: () => QuranData.allSurahs.first,
    ).name;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.islamicGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Islamic Geometric Arabesque Background
            Positioned.fill(
              child: CustomPaint(
                painter: ArabesqueBackgroundPainter(
                  primaryColor: AppColors.gold,
                  opacity: 0.08,
                ),
              ),
            ),
            // Header Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Islamic Date & Crescent motif
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CustomPaint(
                              painter: IslamicStarPainter(color: AppColors.gold, strokeWidth: 1.2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hijriDate,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: AppColors.goldLight, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              '${nextPrayer.nameArabic} : ${nextPrayer.formattedTime}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Centered Daily Verse (آية اليوم)
                  InkWell(
                    onTap: onAyahTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'آية اليوم وتدبّرها',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldLight,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 16),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '﴿ الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'سورة الرعد - آية ٢٨',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.goldLight.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bottom Bookmark Resume Bar (تابع من حيث توقفت)
                  InkWell(
                    onTap: onBookmarkResume,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bookmark_rounded, color: AppColors.primaryDark, size: 22),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'موضع القراءة الحالي',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark.withOpacity(0.8),
                                    ),
                                  ),
                                  Text(
                                    'سورة $surahName • آية $bookmarkAyahNumber',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'متابعة الورد',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryDark, size: 14),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
