import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/islamic_patterns.dart';
import '../../models/ayah_model.dart';
import '../../models/surah_model.dart';
import '../../core/utils/arabic_numbers.dart';

class AyahCardScreen extends StatefulWidget {
  final AyahModel ayah;
  final SurahModel surah;

  const AyahCardScreen({
    super.key,
    required this.ayah,
    required this.surah,
  });

  @override
  State<AyahCardScreen> createState() => _AyahCardScreenState();
}

class _AyahCardScreenState extends State<AyahCardScreen> {
  int _selectedThemeIndex = 0;
  bool _includeTafseer = true;

  final List<Map<String, dynamic>> _cardThemes = [
    {
      'name': 'الزمرد الملكي',
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF0F382C), Color(0xFF061B14)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      'textColor': Colors.white,
      'accentColor': AppColors.gold,
      'isDark': true,
    },
    {
      'name': 'الليل والسكون',
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF111827), Color(0xFF030712)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      'textColor': Colors.white,
      'accentColor': const Color(0xFF60A5FA),
      'isDark': true,
    },
    {
      'name': 'المخطوطة الورقية',
      'bgGradient': const LinearGradient(
        colors: [Color(0xFFFBF6EE), Color(0xFFEDE4D5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'textColor': const Color(0xFF2C2416),
      'accentColor': const Color(0xFF8B5E14),
      'isDark': false,
    },
    {
      'name': 'الذهب النوراني',
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF33260A), Color(0xFF140F03)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'textColor': const Color(0xFFFFF7ED),
      'accentColor': const Color(0xFFFBBF24),
      'isDark': true,
    },
  ];

  void _copyCardText() {
    final buffer = StringBuffer();
    buffer.writeln('﴿ ${widget.ayah.text} ﴾');
    buffer.writeln('[سورة ${widget.surah.name} : آية ${ArabicUtils.toArabicDigits(widget.ayah.numberInSurah)}]');
    if (_includeTafseer && widget.ayah.tafseer != null && widget.ayah.tafseer!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('التفسير:');
      buffer.writeln(widget.ayah.tafseer);
    }
    buffer.writeln();
    buffer.writeln('— عبر تطبيق سَكينة');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ نص البطاقة بنجاح!', style: GoogleFonts.cairo()),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _cardThemes[_selectedThemeIndex];
    final Color textColor = activeTheme['textColor'] as Color;
    final Color accentColor = activeTheme['accentColor'] as Color;
    final Gradient bgGradient = activeTheme['bgGradient'] as Gradient;

    return Scaffold(
      appBar: AppBar(
        title: Text('صانع بطاقات الآيات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.goldLight),
            tooltip: 'نسخ ومشاركة',
            onPressed: _copyCardText,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Preview Card with Islamic Ornaments
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                gradient: bgGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Corner Islamic 8-Pointed Star
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CustomPaint(
                        painter: IslamicStarPainter(color: accentColor, strokeWidth: 1.2),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CustomPaint(
                        painter: IslamicStarPainter(color: accentColor, strokeWidth: 1.2),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Surah & Ayah info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: accentColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              'سورة ${widget.surah.name} • آية ${ArabicUtils.toArabicDigits(widget.ayah.numberInSurah)}',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Verse Text with tashkeel
                      Text(
                        '﴿ ${widget.ayah.text} ﴾',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 2.0,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Tafseer if checked
                      if (_includeTafseer && widget.ayah.tafseer != null && widget.ayah.tafseer!.isNotEmpty) ...[
                        Divider(color: accentColor.withOpacity(0.25), height: 28),
                        Text(
                          widget.ayah.tafseer!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: textColor.withOpacity(0.85),
                            height: 1.6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Watermark / Brand
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.spa_rounded, size: 14, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            'تطبيق سَكينة للقرآن الكريم',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: accentColor.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Theme Selector
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'اختر نمط التصميم:',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _cardThemes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final theme = _cardThemes[index];
                  final isSelected = index == _selectedThemeIndex;
                  return ChoiceChip(
                    label: Text(
                      theme['name'] as String,
                      style: GoogleFonts.cairo(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (_) {
                      setState(() {
                        _selectedThemeIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Options Switch
            SwitchListTile(
              title: Text('تضمين التفسير الميسر', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              value: _includeTafseer,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _includeTafseer = val;
                });
              },
            ),
            const SizedBox(height: 24),
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.goldLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.copy_all_rounded),
                label: Text(
                  'نسخ نص البطاقة للمشاركة',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _copyCardText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
