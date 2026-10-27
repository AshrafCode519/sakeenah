import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/islamic_patterns.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/services/quran_15_lines_service.dart';
import '../../../models/surah_model.dart';
import '../../../models/ayah_model.dart';

/// 15-Line Madani Mushaf Page View (مصحف الـ 15 سطر المنظم والمتقن على طريقة مصحف المدينة وتطبيق آية)
class AyahMushafView extends StatelessWidget {
  final int pageNumber;
  final int? selectedAyahNumberInSurah;
  final int? selectedSurahNumber;
  final int? playingAyahGlobalNumber;
  final int? bookmarkAyahNumberInSurah;
  final int? bookmarkSurahNumber;
  final Function(AyahModel ayah) onAyahSelected;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const AyahMushafView({
    super.key,
    required this.pageNumber,
    required this.selectedAyahNumberInSurah,
    this.selectedSurahNumber,
    required this.playingAyahGlobalNumber,
    required this.bookmarkAyahNumberInSurah,
    this.bookmarkSurahNumber,
    required this.onAyahSelected,
    this.onNextPage,
    this.onPreviousPage,
    this.hasNextPage = true,
    this.hasPreviousPage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = Quran15LinesService.instance;
    final lines = service.parsePage(pageNumber);
    final primarySurah = service.getSurahForPage(pageNumber);
    final juzNumber = Quran15LinesService.getJuzForPage(pageNumber);
    final hizbNumber = Quran15LinesService.getHizbForPage(pageNumber);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          children: [
            // 1. الشريط العلوي لترويسة الصفحة (اسم السورة • الحزب • الجزء)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سُورَةُ ${primarySurah.name}',
                    style: GoogleFonts.amiri(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldLight : AppColors.primary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CustomPaint(
                          painter: IslamicStarPainter(color: AppColors.gold, strokeWidth: 1.0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الحِزْبُ ${ArabicUtils.toArabicDigits(hizbNumber)}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : AppColors.goldDark,
                        ),
                      ),
                    ],
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

            // 2. إطار صفحة المصحف الشريف ذو الإطار المذهب المزدوج
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A16) : const Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(isDark ? 0.65 : 0.8),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.5 : 0.09),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  // الإطار الزخرفي الداخلي الدقيق (Inner Ornate Frame)
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(isDark ? 0.35 : 0.45),
                      width: 1.0,
                    ),
                  ),
                  child: lines.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.gold),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildPageLines(context, lines, pageNumber, isDark),
                        ),
                ),
              ),
            ),

            // 3. الشريط السفلي لتقليب الصفحات ورقم الصفحة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // زر السابقة (في اليمين لاتجاه القراءة العربي)
                  TextButton.icon(
                    onPressed: hasPreviousPage ? onPreviousPage : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                    label: Text(
                      'السابقة',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      disabledForegroundColor: Colors.grey.withOpacity(0.3),
                    ),
                  ),

                  // شارة رقم الصفحة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withOpacity(0.4)),
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

                  // زر التالية (في اليسار لاتجاه القراءة العربي)
                  TextButton.icon(
                    onPressed: hasNextPage ? onNextPage : null,
                    label: Text(
                      'التالية',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 13),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      disabledForegroundColor: Colors.grey.withOpacity(0.3),
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

  /// Organizes page lines with balanced layout for frontispiece pages 1 & 2 vs normal pages
  List<Widget> _buildPageLines(
    BuildContext context,
    List<MushafLineData> lines,
    int pageNumber,
    bool isDark,
  ) {
    if (pageNumber == 1 || pageNumber == 2) {
      final ornamentCount = lines.where((l) => l.type == MushafLineType.ornamentHeader).length;
      final remainingLines = lines.skip(ornamentCount).toList();

      return [
        if (ornamentCount > 0)
          Expanded(
            flex: 3, // ترويسة مذهبة متناسقة وراقية تشغل ~20% فقط من الصفحة
            child: _buildFrontispieceOrnament(isDark, pageNumber),
          ),
        ...remainingLines.map(
          (lineData) {
            if (lineData.type == MushafLineType.surahHeader) {
              return Expanded(
                flex: 1,
                child: _buildSurahBanner(lineData.surah, isDark),
              );
            }
            // الآيات في الصفحتين 1 و 2 تأخذ flex: 2 لتكون كبيرة ومريحة وواضحة جداً
            return Expanded(
              flex: 2,
              child: _buildMushafLine(context, lineData, isDark, isFrontispiecePage: true),
            );
          },
        ),
      ];
    }

    // الصفحات العادية (3 إلى 604): 15 سطراً متناسقاً
    return List.generate(lines.length.clamp(0, 15), (index) {
      final lineData = lines[index];
      return Expanded(
        flex: 1,
        child: _buildMushafLine(context, lineData, isDark),
      );
    });
  }

  /// Builds a single line in the Mushaf Page
  Widget _buildMushafLine(
    BuildContext context,
    MushafLineData lineData,
    bool isDark, {
    bool isFrontispiecePage = false,
  }) {
    switch (lineData.type) {
      case MushafLineType.ornamentHeader:
        return _buildOrnamentHeader(isDark);

      case MushafLineType.surahHeader:
        return _buildSurahBanner(lineData.surah, isDark);

      case MushafLineType.basmalah:
        return _buildBasmalah(isDark);

      case MushafLineType.text:
        return _buildTextLine(context, lineData, isDark, isFrontispiecePage: isFrontispiecePage);
    }
  }

  /// Majestic Frontispiece Ornamental Illumination (لوحة زخرفية ملكية لترويسة بداية المصحف)
  Widget _buildFrontispieceOrnament(bool isDark, int pageNumber) {
    final title = pageNumber == 1 ? 'فَاتِحَةُ الكِتَابِ' : 'أَوَائِلُ سُورَةِ البَقَرَةِ';
    final subtitle = pageNumber == 1 ? 'مَكِّيَّة • سَبْعُ آيَاتٍ' : 'مَدَنِيَّة • سَيِّدَةُ آيِ القُرْآنِ';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A2F), const Color(0xFF11261D)]
              : [const Color(0xFFFBF8F0), const Color(0xFFEDE4D1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الزخرفة العلوية
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 1.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.gold],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CustomPaint(
                      painter: IslamicStarPainter(color: AppColors.gold, strokeWidth: 1.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 1.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.gold, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // العنوان المخطوط
              Text(
                title,
                style: GoogleFonts.amiri(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldLight : AppColors.primary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              // الوصف
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withOpacity(0.35), width: 0.8),
                ),
                child: Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.goldDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Single line ornament fallback
  Widget _buildOrnamentHeader(bool isDark) {
    return Center(
      child: Container(
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.gold.withOpacity(isDark ? 0.35 : 0.5),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  /// Ornate Surah Header Banner (ترويسة السورة المذهبة)
  Widget _buildSurahBanner(SurahModel? surah, bool isDark) {
    final surahName = surah?.name ?? '';
    final versesCount = surah?.numberOfAyahs ?? 0;
    final revelation = surah?.revelationArabic ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F3D30), const Color(0xFF142920), const Color(0xFF1F3D30)]
              : [const Color(0xFFF8F3E8), const Color(0xFFEFE4CF), const Color(0xFFF8F3E8)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.85),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CustomPaint(
              painter: IslamicStarPainter(color: AppColors.gold, strokeWidth: 1.1),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'سُورَةُ $surahName',
                  style: GoogleFonts.amiri(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldLight : AppColors.primary,
                  ),
                ),
                if (versesCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(isDark ? 0.2 : 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$revelation • آيَاتُهَا ${ArabicUtils.toArabicDigits(versesCount)}',
                      style: GoogleFonts.cairo(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldLight : AppColors.goldDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 16,
            height: 16,
            child: CustomPaint(
              painter: IslamicStarPainter(color: AppColors.gold, strokeWidth: 1.1),
            ),
          ),
        ],
      ),
    );
  }

  /// Ornate Basmalah Line (البسملة الكريمة)
  Widget _buildBasmalah(bool isDark) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '۞  ',
              style: TextStyle(
                color: AppColors.gold.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: GoogleFonts.amiri(
                fontSize: 18.5,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.goldLight : AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '  ۞',
              style: TextStyle(
                color: AppColors.gold.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quranic Text Line (سطر الآيات القرآنية مع علامات الآيات والتظليل)
  Widget _buildTextLine(
    BuildContext context,
    MushafLineData lineData,
    bool isDark, {
    bool isFrontispiecePage = false,
  }) {
    final spans = <InlineSpan>[];
    final verseFontSize = isFrontispiecePage ? 22.0 : 19.5;
    final markerFontSize = isFrontispiecePage ? 18.0 : 16.5;

    for (final seg in lineData.segments) {
      final isSelected = (selectedSurahNumber == null || selectedSurahNumber == seg.surahNumber) &&
          selectedAyahNumberInSurah == seg.ayahNumberInSurah;
      final isPlaying = playingAyahGlobalNumber == seg.globalAyahNumber;

      Color? bgColor;
      if (isPlaying) {
        bgColor = AppColors.gold.withOpacity(0.4);
      } else if (isSelected) {
        bgColor = isDark
            ? AppColors.gold.withOpacity(0.25)
            : const Color(0xFFEADBBE); // Warm parchment highlight like Ayah app
      }

      if (seg.isVerseMarker) {
        // علامة نهاية الآية المذهبة: ﴿١﴾
        final markerText = ' ﴿${ArabicUtils.toArabicDigits(seg.verseNumber ?? seg.ayahNumberInSurah)}﴾ ';
        spans.add(
          TextSpan(
            text: markerText,
            style: GoogleFonts.amiri(
              fontSize: markerFontSize,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? (isDark ? AppColors.goldLight : AppColors.primary)
                  : (isDark ? AppColors.goldLight : AppColors.goldDark),
              backgroundColor: bgColor,
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _triggerAyahSelect(seg),
          ),
        );
      } else {
        // كلمات الآية الكريمة
        spans.add(
          TextSpan(
            text: '${seg.text} ',
            style: GoogleFonts.amiri(
              fontSize: verseFontSize,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF2F4F3) : const Color(0xFF141F1A),
              backgroundColor: bgColor,
              letterSpacing: isFrontispiecePage ? 0.35 : 0.2,
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _triggerAyahSelect(seg),
          ),
        );
      }
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  void _triggerAyahSelect(MushafLineSegment seg) {
    final ayah = AyahModel(
      number: seg.globalAyahNumber,
      numberInSurah: seg.ayahNumberInSurah,
      surahNumber: seg.surahNumber,
      page: pageNumber,
      juz: Quran15LinesService.getJuzForPage(pageNumber),
      text: seg.text,
      audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${seg.globalAyahNumber}.mp3',
    );
    onAyahSelected(ayah);
  }
}
