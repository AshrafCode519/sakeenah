import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/services/storage_service.dart';
import '../data/quran_data.dart';
import '../data/locations_data.dart';
import '../models/location_model.dart';
import 'widgets/islamic_header_card.dart';
import 'widgets/wird_rings_card.dart';
import 'widgets/floating_athkar_banner.dart';
import 'quran/quran_index_screen.dart';
import 'quran/surah_reader_screen.dart';
import 'quran/ayah_card_screen.dart';
import 'athkar/athkar_categories_screen.dart';
import 'masbaha/masbaha_screen.dart';
import 'prayers/prayers_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool isDark)? onThemeChanged;

  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  bool _morningDone = false;
  bool _eveningDone = false;
  int _quranPages = 0;
  int _tasbihCount = 0;
  int _bookmarkSurah = 1;
  int _bookmarkAyah = 1;
  bool _floatingAthkarEnabled = true;
  LocationModel _currentLocation = LocationsData.allLocations.first;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final storage = await StorageService.getInstance();
    final country = storage.selectedCountry;
    final city = storage.selectedCity;
    final governorate = storage.selectedGovernorate;
    setState(() {
      _currentLocation = LocationsData.getLocation(country, city, governorate);
      _morningDone = storage.morningWirdDone;
      _eveningDone = storage.eveningWirdDone;
      _quranPages = storage.dailyQuranPages;
      _tasbihCount = storage.dailyTasbihCount;
      _bookmarkSurah = storage.bookmarkSurah;
      _bookmarkAyah = storage.bookmarkAyah;
      _floatingAthkarEnabled = storage.floatingAthkarEnabled;
    });
  }

  void _openBookmarkReader() {
    final surah = QuranData.allSurahs.firstWhere(
      (s) => s.number == _bookmarkSurah,
      orElse: () => QuranData.allSurahs.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(surah: surah, initialAyah: _bookmarkAyah),
      ),
    ).then((_) => _loadState());
  }

  void _openDailyAyahCard() {
    final surah = QuranData.allSurahs[12]; // Ar-Ra'd
    final ayah = QuranData.ayatAlKursi;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AyahCardScreen(ayah: ayah, surah: surah),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _buildHomeDashboard(context),
      const QuranIndexScreen(),
      const AthkarCategoriesScreen(),
      const MasbahaScreen(),
      const PrayersScreen(),
    ];

    return Scaffold(
      appBar: _currentNavIndex == 0
          ? AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.spa_rounded, color: AppColors.gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'سَكِينة',
                    style: GoogleFonts.amiri(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLight,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: AppColors.goldLight,
                  ),
                  tooltip: 'تبديل المظهر',
                  onPressed: () async {
                    final storage = await StorageService.getInstance();
                    final newDark = !isDark;
                    await storage.setDarkMode(newDark);
                    widget.onThemeChanged?.call(newDark);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.goldLight),
                  tooltip: 'الإعدادات',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(onThemeChanged: widget.onThemeChanged),
                      ),
                    ).then((_) => _loadState());
                  },
                ),
              ],
            )
          : null,
      body: pages[_currentNavIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentNavIndex = idx);
          _loadState();
        },
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: AppColors.primary),
            label: 'المصحف',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism_rounded, color: AppColors.primary),
            label: 'الأذكار',
          ),
          NavigationDestination(
            icon: Icon(Icons.fingerprint_outlined),
            selectedIcon: Icon(Icons.fingerprint_rounded, color: AppColors.primary),
            label: 'السبحة',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled_rounded, color: AppColors.primary),
            label: 'المواقيت',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadState,
      color: AppColors.primary,
      child: ListView(
        children: [
          // 1. Grand Islamic Hero Card
          IslamicHeaderCard(
            location: _currentLocation,
            bookmarkSurahNumber: _bookmarkSurah,
            bookmarkAyahNumber: _bookmarkAyah,
            onBookmarkResume: _openBookmarkReader,
            onAyahTap: _openDailyAyahCard,
          ),
          // 2. Periodic Floating Athkar Banner
          if (_floatingAthkarEnabled) const FloatingAthkarBanner(),
          // 3. Daily Wird Rings Tracker
          WirdRingsCard(
            morningDone: _morningDone,
            eveningDone: _eveningDone,
            quranPages: _quranPages,
            tasbihCount: _tasbihCount,
            onRefresh: _loadState,
          ),
          const SizedBox(height: 12),
          // 4. Quick Access Features Grid Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المحاور والخدمات الرئيسية',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldLight : AppColors.primary,
                  ),
                ),
                Text(
                  'اختر قسماً',
                  style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 5. Quick Features Grid (2 columns)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.25,
              children: [
                _buildFeatureCard(
                  context,
                  title: 'المصحف الشريف',
                  subtitle: '١١٤ سورة مع التفسير والتلاوة',
                  icon: Icons.menu_book_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F382C), Color(0xFF165342)],
                  ),
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                _buildFeatureCard(
                  context,
                  title: 'حصن المسلم',
                  subtitle: 'أذكار الصباح والمساء والنوم',
                  icon: Icons.shield_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFB45309)],
                  ),
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
                _buildFeatureCard(
                  context,
                  title: 'السبحة الذكية',
                  subtitle: 'تسبيح وأوراد يومية تفاعلية',
                  icon: Icons.fingerprint_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  onTap: () => setState(() => _currentNavIndex = 3),
                ),
                _buildFeatureCard(
                  context,
                  title: 'مواقيت الصلاة',
                  subtitle: 'أوقات الصلوات والقبلة',
                  icon: Icons.mosque_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  onTap: () => setState(() => _currentNavIndex = 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 6. Ayah Card Maker Callout Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2E2211), const Color(0xFF191206)]
                    : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.style_rounded, color: AppColors.goldDark, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صانع بطاقات الآيات والتدبر',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldLight : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'حوّل الآيات إلى بطاقات إسلامية مصورة للمشاركة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.goldLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _openDailyAyahCard,
                  child: Text('صمّم بطاقة', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
