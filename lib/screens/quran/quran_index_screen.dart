import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/islamic_patterns.dart';
import '../../data/quran_data.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/services/storage_service.dart';
import 'surah_reader_screen.dart';

class QuranIndexScreen extends StatefulWidget {
  const QuranIndexScreen({super.key});

  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends State<QuranIndexScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'Meccan', 'Medinan'
  int _bookmarkSurah = 1;
  int _bookmarkAyah = 1;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _bookmarkSurah = storage.bookmarkSurah;
      _bookmarkAyah = storage.bookmarkAyah;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredSurahs = QuranData.allSurahs.where((s) {
      final matchesSearch = s.name.contains(_searchQuery) ||
          s.englishName.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_filterType == 'Meccan') {
        return matchesSearch && s.isMeccan;
      } else if (_filterType == 'Medinan') {
        return matchesSearch && !s.isMeccan;
      }
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'فهرس القرآن الكريم',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.gold.withOpacity(0.2)),
              ),
            ),
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن سورة بالاسم...',
                    hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.parchment,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.gold.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter Segment Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterChip('الكل', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('السور المكية (٨٦)', 'Meccan'),
                    const SizedBox(width: 8),
                    _buildFilterChip('السور المدنية (٢٨)', 'Medinan'),
                  ],
                ),
              ],
            ),
          ),
          // Bookmark Resume Banner
          InkWell(
            onTap: () {
              final surah = QuranData.allSurahs.firstWhere(
                (s) => s.number == _bookmarkSurah,
                orElse: () => QuranData.allSurahs.first,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahReaderScreen(surah: surah, initialAyah: _bookmarkAyah),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bookmark_added_rounded, color: AppColors.gold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'موضع ختمتك الحالية: سورة ${QuranData.allSurahs.firstWhere((s) => s.number == _bookmarkSurah, orElse: () => QuranData.allSurahs.first).name} (آية $_bookmarkAyah)',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldLight : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.gold),
                ],
              ),
            ),
          ),
          // Surahs List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredSurahs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final surah = filteredSurahs[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.gold.withOpacity(0.15)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(40, 40),
                            painter: IslamicStarPainter(
                              color: AppColors.gold,
                              strokeWidth: 1.2,
                            ),
                          ),
                          Text(
                            ArabicUtils.toArabicDigits(surah.number),
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.goldLight : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سورة ${surah.name}',
                          style: GoogleFonts.amiri(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        Text(
                          surah.englishName,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: surah.isMeccan
                                ? Colors.amber.withOpacity(0.15)
                                : Colors.teal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            surah.revelationArabic,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: surah.isMeccan ? Colors.amber[800] : Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${ArabicUtils.toArabicDigits(surah.numberOfAyahs)} آيات',
                          style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          'صفحة ${ArabicUtils.toArabicDigits(surah.startPage)}',
                          style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.gold,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurahReaderScreen(surah: surah),
                        ),
                      );
                      _loadBookmark();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => setState(() => _filterType = type),
    );
  }
}
