import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/islamic_patterns.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../models/surah_model.dart';
import '../../../models/ayah_model.dart';

class AyahMushafView extends StatelessWidget {
  final SurahModel surah;
  final List<AyahModel> ayahs;
  final int pageNumber;
  final int juzNumber;
  final bool showSurahHeader;
  final bool showBasmalah;
  final int? selectedAyahNumberInSurah;
  final int? bookmarkAyahNumberInSurah;
  final int? playingAyahGlobalNumber;
  final double fontSize;
  final Function(AyahModel ayah) onAyahSelected;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const AyahMushafView({
    super.key,
    required this.surah,
    required this.ayahs,
    this.pageNumber = 1,
    this.juzNumber = 1,
    this.showSurahHeader = false,
    this.showBasmalah = false,
    required this.selectedAyahNumberInSurah,
    required this.bookmarkAyahNumberInSurah,
    required this.playingAyahGlobalNumber,
    required this.fontSize,
    required this.onAyahSelected,
    this.onNextPage,
    this.onPreviousPage,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // 1. Top Mushaf Page Header Ribbon (سورة ... • علامة النجمة • الجزء ...)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سُورَةُ ${surah.name}',
                style: GoogleFonts.amiri(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldLight : AppColors.primary,
                ),
              ),
              SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(
                  painter: IslamicStarPainter(color: AppColors.gold, strokeWidth: 1.0),
                ),
              ),
              Text(
                ArabicUtils.getJuzName(juzNumber),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldLight : AppColors.goldDark,
                ),
              ),
            ],
          ),
        ),

        // 2. Mushaf Page Canvas Frame (إطار صفحة المصحف الشريف المذهب)
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFFDFBF7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withOpacity(isDark ? 0.35 : 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ornate Surah Header Frame if this page contains Ayah 1
                  if (showSurahHeader) ...[
                    _buildSurahHeaderBanner(context),
                    const SizedBox(height: 14),
                  ],

                  // Basmalah if required
                  if (showBasmalah) ...[
                    _buildBasmalah(context),
                    const SizedBox(height: 16),
                  ],

                  // Continuous Flowing Quranic Verses on this Page
                  _buildContinuousQuranText(context),
                ],
              ),
            ),
          ),
        ),

        // 3. Bottom Mushaf Page Footer (رقم الصفحة وأزرار تقليب الصفحات مثل تطبيق آية)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Page Button (السابقة)
              TextButton.icon(
                onPressed: hasPreviousPage ? onPreviousPage : null,
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                label: Text(
                  'السابقة',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  disabledForegroundColor: Colors.grey.withOpacity(0.3),
                ),
              ),

              // Mushaf Page Number Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Text(
                  '— ${ArabicUtils.toArabicDigits(pageNumber)} —',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                  ),
                ),
              ),

              // Next Page Button (التالية)
              TextButton.icon(
                onPressed: hasNextPage ? onNextPage : null,
                label: Text(
                  'التالية',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  disabledForegroundColor: Colors.grey.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Ornate Surah Header Frame
  Widget _buildSurahHeaderBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF163227), const Color(0xFF0F221A)]
              : [const Color(0xFFF3ECE0), const Color(0xFFE8DDCD)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Star
          SizedBox(
            width: 26,
            height: 26,
            child: CustomPaint(
              painter: IslamicStarPainter(color: AppColors.gold, strokeWidth: 1.2),
            ),
          ),
          // Center Surah Name & Info
          Column(
            children: [
              Text(
                'سُورَةُ ${surah.name}',
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldLight : AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${surah.revelationArabic} • آيَاتُهَا ${ArabicUtils.toArabicDigits(surah.numberOfAyahs)}',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.goldDark,
                ),
              ),
            ],
          ),
          // Right Star
          SizedBox(
            width: 26,
            height: 26,
            child: CustomPaint(
              painter: IslamicStarPainter(color: AppColors.gold, strokeWidth: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  /// Basmalah
  Widget _buildBasmalah(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        style: GoogleFonts.amiri(
          fontSize: fontSize + 2,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.goldLight : AppColors.primary,
        ),
      ),
    );
  }

  /// Continuous Quranic Flow with Tap-to-Highlight
  Widget _buildContinuousQuranText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final spans = <InlineSpan>[];

    for (final ayah in ayahs) {
      final isSelected = selectedAyahNumberInSurah == ayah.numberInSurah;
      final isPlaying = playingAyahGlobalNumber == ayah.number;
      final isBookmarked = bookmarkAyahNumberInSurah == ayah.numberInSurah;

      // Color tint for selected or playing ayah
      Color? bgColor;
      if (isPlaying) {
        bgColor = AppColors.gold.withOpacity(0.35);
      } else if (isSelected) {
        bgColor = isDark
            ? AppColors.gold.withOpacity(0.22)
            : const Color(0xFFE8E2CD); // Soothing gold paper highlight like Ayah app
      }

      // Clean duplicate leading Basmalah from Ayah 1 (except Surah Al-Fatihah where Basmalah is Ayah 1)
      String cleanText = ayah.text;
      if (surah.number != 1 && ayah.numberInSurah == 1) {
        cleanText = cleanText.replaceFirst(
          RegExp(r'^بِسْمِ\s+[^\s]+\s+[^\s]+\s+[^\s]+\s*'),
          '',
        ).trim();
      }

      // Verse Text
      spans.add(
        TextSpan(
          text: '$cleanText ',
          style: GoogleFonts.amiri(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF3F5F4) : const Color(0xFF141F1A),
            backgroundColor: bgColor,
            height: 2.3,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onAyahSelected(ayah),
        ),
      );

      // Ayah End Marker in authentic Quranic Mushaf typography (رقم الآية المذهب)
      final bookmarkMark = isBookmarked ? '🔖' : '';
      final ayahMarker = '$bookmarkMark﴿${ArabicUtils.toArabicDigits(ayah.numberInSurah)}﴾';

      spans.add(
        TextSpan(
          text: '$ayahMarker ',
          style: GoogleFonts.amiri(
            fontSize: fontSize * 0.92,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? (isDark ? AppColors.goldLight : AppColors.primary)
                : (isDark ? AppColors.goldLight : AppColors.goldDark),
            backgroundColor: bgColor,
            letterSpacing: 0.5,
            height: 2.3,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onAyahSelected(ayah),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }
}
