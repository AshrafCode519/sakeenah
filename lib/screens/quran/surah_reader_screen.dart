import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../models/surah_model.dart';
import '../../models/ayah_model.dart';
import '../../data/quran_data.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/quran_15_lines_service.dart';
import 'widgets/ayah_mushaf_view.dart';
import 'widgets/ayah_action_toolbar.dart';
import 'widgets/mushaf_tafseer_sheet.dart';
import 'ayah_card_screen.dart';

class SurahReaderScreen extends StatefulWidget {
  final SurahModel surah;
  final int initialAyah;

  const SurahReaderScreen({
    super.key,
    required this.surah,
    this.initialAyah = 1,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  int _currentPage = 1;
  late PageController _pageController;
  bool _isLoading = true;
  bool _isMushafPageView = true;

  AyahModel? _selectedAyah;
  int? _bookmarkAyahNumber;
  int? _bookmarkSurahNumber;
  int? _bookmarkPageNumber;
  int? _activePlayingAyah;

  final QuranAudioService _audioService = QuranAudioService();

  // For card view mode fallback
  List<AyahModel> _cardModeAyahs = [];

  @override
  void initState() {
    super.initState();
    _initReader();
    _audioService.currentAyahPlaying.addListener(_onAudioAyahChanged);
  }

  @override
  void dispose() {
    _audioService.currentAyahPlaying.removeListener(_onAudioAyahChanged);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initReader() async {
    // 1. Initialize 15-line dataset
    await Quran15LinesService.instance.init();

    // 2. Load saved bookmark
    final storage = await StorageService.getInstance();
    _bookmarkSurahNumber = storage.bookmarkSurah;
    _bookmarkAyahNumber = storage.bookmarkAyah;
    _bookmarkPageNumber = storage.bookmarkPage;

    // 3. Determine start page
    int targetPage = widget.surah.startPage;
    if (widget.initialAyah > 1) {
      targetPage = _findPageForAyah(widget.surah.number, widget.initialAyah);
    } else if (widget.surah.number == _bookmarkSurahNumber && _bookmarkPageNumber != null) {
      targetPage = _bookmarkPageNumber!;
    }

    _currentPage = targetPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    _loadCardModeAyahs();
  }

  int _findPageForAyah(int surahNum, int ayahNum) {
    int bestPage = widget.surah.startPage;
    final starts = Quran15LinesService.pageStarts;
    for (int p = 0; p < starts.length; p++) {
      final s = starts[p];
      if (s[0] == surahNum && s[1] <= ayahNum) {
        bestPage = p + 1;
      } else if (s[0] > surahNum) {
        break;
      }
    }
    return bestPage;
  }

  void _onAudioAyahChanged() {
    if (mounted) {
      final active = _audioService.currentAyahPlaying.value;
      setState(() {
        _activePlayingAyah = active;
      });
    }
  }

  void _onPageChanged(int index) {
    final newPage = index + 1;
    setState(() {
      _currentPage = newPage;
      _selectedAyah = null;
    });

    StorageService.getInstance().then((storage) {
      storage.addDailyQuranPage();
    });
  }

  void _onAyahSelected(AyahModel ayah) {
    setState(() {
      if (_selectedAyah?.numberInSurah == ayah.numberInSurah &&
          _selectedAyah?.surahNumber == ayah.surahNumber) {
        _selectedAyah = null;
      } else {
        _selectedAyah = ayah;
      }
    });
  }

  void _goToNextPage() {
    if (_currentPage < 604 && _pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && _pageController.hasClients) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  void _jumpToPage(int page) {
    final clamped = page.clamp(1, 604);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(clamped - 1);
    }
    setState(() {
      _currentPage = clamped;
      _selectedAyah = null;
    });
  }

  void _playRecitation(AyahModel ayah) {
    if (_activePlayingAyah == ayah.number) {
      _audioService.stop();
    } else {
      _audioService.playAyahAudio(
        globalAyahNumber: ayah.number,
        customUrl: ayah.audioUrl,
      );
    }
  }

  void _openTafseer(AyahModel ayah) {
    final surah = QuranData.allSurahs.firstWhere(
      (s) => s.number == ayah.surahNumber,
      orElse: () => widget.surah,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MushafTafseerSheet(ayah: ayah, surah: surah),
    );
  }

  void _setBookmark(AyahModel ayah) async {
    final storage = await StorageService.getInstance();
    await storage.saveBookmark(
      surah: ayah.surahNumber,
      ayah: ayah.numberInSurah,
      page: _currentPage,
    );
    if (!mounted) return;
    setState(() {
      _bookmarkSurahNumber = ayah.surahNumber;
      _bookmarkAyahNumber = ayah.numberInSurah;
      _bookmarkPageNumber = _currentPage;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ الفاصلة عند الآية () صفحة () بنجاح',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAyahCard(AyahModel ayah) {
    final surah = QuranData.allSurahs.firstWhere(
      (s) => s.number == ayah.surahNumber,
      orElse: () => widget.surah,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AyahCardScreen(ayah: ayah, surah: surah),
      ),
    );
  }

  void _copyAyah(AyahModel ayah) {
    final surah = QuranData.allSurahs.firstWhere(
      (s) => s.number == ayah.surahNumber,
      orElse: () => widget.surah,
    );
    Clipboard.setData(ClipboardData(
      text: '﴿' + ayah.text + '﴾ [سورة ' + surah.name + ': ' + ayah.numberInSurah.toString() + ']',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الآية الكريمة إلى الحافظة', style: GoogleFonts.cairo()),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openQuickJumpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickJumpSheet(
        currentPage: _currentPage,
        onPageSelected: (page) {
          Navigator.pop(ctx);
          _jumpToPage(page);
        },
      ),
    );
  }

  Future<void> _loadCardModeAyahs() async {
    final cached = QuranData.builtInSurahs[widget.surah.number];
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _cardModeAyahs = cached;
        });
      }
      return;
    }

    try {
      final url = Uri.parse(
          'https://api.alquran.cloud/v1/surah/${widget.surah.number}/editions/quran-uthmani,ar.muyassar');
      final response = await http.get(url).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final editions = data['data'] as List<dynamic>;
        final uthmaniAyahs = editions[0]['ayahs'] as List<dynamic>;
        final tafseerAyahs = editions[1]['ayahs'] as List<dynamic>;

        final fetchedList = <AyahModel>[];
        for (int i = 0; i < uthmaniAyahs.length; i++) {
          final u = uthmaniAyahs[i];
          final t = tafseerAyahs[i];
          fetchedList.add(AyahModel(
            number: u['number'] as int,
            numberInSurah: u['numberInSurah'] as int,
            surahNumber: widget.surah.number,
            juz: u['juz'] as int? ?? 1,
            page: u['page'] as int? ?? 1,
            text: u['text'] as String,
            tafseer: t['text'] as String,
            audioUrl:
                'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${u['number']}.mp3',
          ));
        }

        if (mounted) {
          setState(() {
            _cardModeAyahs = fetchedList;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSurah = Quran15LinesService.instance.getSurahForPage(_currentPage);
    final currentJuz = Quran15LinesService.getJuzForPage(_currentPage);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1410) : const Color(0xFFEBE5D8),
      appBar: AppBar(
        title: InkWell(
          onTap: _openQuickJumpDialog,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'سُورَةُ ' + currentSurah.name,
                      style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded, size: 20),
                  ],
                ),
                Text(
                  ArabicUtils.getJuzName(currentJuz) + ' • صفحة ' + ArabicUtils.toArabicDigits(_currentPage),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : AppColors.goldLight,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Bookmark shortcut
          IconButton(
            icon: Icon(
              _bookmarkPageNumber == _currentPage
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
            color: _bookmarkPageNumber == _currentPage ? Colors.amber : null,
            tooltip: 'حفظ الفاصلة عند هذه الصفحة',
            onPressed: () {
              final activeSurah = currentSurah.number;
              StorageService.getInstance().then((storage) {
                storage.saveBookmark(
                  surah: activeSurah,
                  ayah: 1,
                  page: _currentPage,
                );
                if (!mounted) return;
                setState(() {
                  _bookmarkPageNumber = _currentPage;
                  _bookmarkSurahNumber = activeSurah;
                  _bookmarkAyahNumber = 1;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم حفظ الفاصلة عند صفحة ${ArabicUtils.toArabicDigits(_currentPage)}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              });
            },
          ),
          // Toggle between 15-line Mushaf view and list cards view
          IconButton(
            icon: Icon(_isMushafPageView ? Icons.view_agenda_outlined : Icons.menu_book_rounded),
            tooltip: _isMushafPageView
                ? 'عرض البطاقات المنفصلة'
                : 'مصحف الـ 15 سطر (تطبيق آية)',
            onPressed: () {
              setState(() {
                _isMushafPageView = !_isMushafPageView;
                _selectedAyah = null;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Stack(
              children: [
                _isMushafPageView
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: 604,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final pageNum = index + 1;
                          return AyahMushafView(
                            pageNumber: pageNum,
                            selectedAyahNumberInSurah: _selectedAyah?.numberInSurah,
                            selectedSurahNumber: _selectedAyah?.surahNumber,
                            playingAyahGlobalNumber: _activePlayingAyah,
                            bookmarkAyahNumberInSurah: _bookmarkAyahNumber,
                            bookmarkSurahNumber: _bookmarkSurahNumber,
                            onAyahSelected: _onAyahSelected,
                            onNextPage: _goToNextPage,
                            onPreviousPage: _goToPreviousPage,
                            hasNextPage: pageNum < 604,
                            hasPreviousPage: pageNum > 1,
                          );
                        },
                      )
                    : _buildCardListView(isDark),

                // Floating Action Toolbar on Selected Ayah
                if (_selectedAyah != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AyahActionToolbar(
                      ayah: _selectedAyah!,
                      surah: QuranData.allSurahs.firstWhere(
                        (s) => s.number == _selectedAyah!.surahNumber,
                        orElse: () => currentSurah,
                      ),
                      isPlaying: _activePlayingAyah == _selectedAyah!.number,
                      isBookmarked: _bookmarkAyahNumber == _selectedAyah!.numberInSurah &&
                          _bookmarkSurahNumber == _selectedAyah!.surahNumber,
                      onPlay: () => _playRecitation(_selectedAyah!),
                      onTafseer: () => _openTafseer(_selectedAyah!),
                      onBookmark: () => _setBookmark(_selectedAyah!),
                      onShareCard: () => _openAyahCard(_selectedAyah!),
                      onCopy: () => _copyAyah(_selectedAyah!),
                      onClose: () => setState(() => _selectedAyah = null),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCardListView(bool isDark) {
    if (_cardModeAyahs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          itemCount: _cardModeAyahs.length,
          itemBuilder: (context, index) {
            final ayah = _cardModeAyahs[index];
            final isSelected = _selectedAyah?.numberInSurah == ayah.numberInSurah;
            final isPlaying = _activePlayingAyah == ayah.number;

            return InkWell(
              onTap: () => _onAyahSelected(ayah),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppColors.gold.withOpacity(0.28)
                      : isSelected
                          ? AppColors.gold.withOpacity(0.18)
                          : (isDark ? AppColors.darkSurface : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isPlaying || isSelected)
                        ? AppColors.gold
                        : AppColors.gold.withOpacity(0.25),
                    width: (isPlaying || isSelected) ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Top Bar with Ayah Badge and Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                          ),
                          child: Text(
                            'آية ${ArabicUtils.toArabicDigits(ayah.numberInSurah)}',
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.goldLight : AppColors.goldDark,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                                color: isPlaying ? AppColors.gold : AppColors.primary,
                                size: 22,
                              ),
                              tooltip: isPlaying ? 'إيقاف التلاوة' : 'استماع للآية',
                              onPressed: () => _playRecitation(ayah),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              color: AppColors.goldDark,
                              tooltip: 'نسخ الآية',
                              onPressed: () => _copyAyah(ayah),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Quranic Verse Text
                    Text(
                      '${ayah.text} ﴿${ArabicUtils.toArabicDigits(ayah.numberInSurah)}﴾',
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 22.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF2F4F3) : const Color(0xFF141F1A),
                        height: 2.1,
                      ),
                    ),

                    // Tafseer Box
                    if (ayah.tafseer != null && ayah.tafseer!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : const Color(0xFFFAF7EE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold.withOpacity(0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'المختصر في التفسير:',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ayah.tafseer!,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickJumpSheet extends StatefulWidget {
  final int currentPage;
  final Function(int page) onPageSelected;

  const _QuickJumpSheet({
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  State<_QuickJumpSheet> createState() => _QuickJumpSheetState();
}

class _QuickJumpSheetState extends State<_QuickJumpSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.gold,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.gold,
            tabs: const [
              Tab(text: 'السور'),
              Tab(text: 'الأجزاء'),
              Tab(text: 'الصفحات'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Surahs List
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'ابحث عن اسم السورة...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onChanged: (val) => setState(() => _search = val),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: QuranData.allSurahs.length,
                        itemBuilder: (context, idx) {
                          final surah = QuranData.allSurahs[idx];
                          if (_search.isNotEmpty && !surah.name.contains(_search)) {
                            return const SizedBox.shrink();
                          }
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.gold.withOpacity(0.15),
                              child: Text(
                                ArabicUtils.toArabicDigits(surah.number),
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldDark,
                                ),
                              ),
                            ),
                            title: Text(
                              'سورة ${surah.name}',
                              style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${surah.revelationArabic} • آياتها ${ArabicUtils.toArabicDigits(surah.numberOfAyahs)}',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            trailing: Text(
                              'ص ${ArabicUtils.toArabicDigits(surah.startPage)}',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                            ),
                            onTap: () => widget.onPageSelected(surah.startPage),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // 2. Juz List (1..30)
                ListView.builder(
                  itemCount: 30,
                  itemBuilder: (context, idx) {
                    final juzNum = idx + 1;
                    final startPage = (juzNum == 1) ? 1 : ((juzNum - 1) * 20 + 2);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.gold.withOpacity(0.15),
                        child: Text(
                          ArabicUtils.toArabicDigits(juzNum),
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        ArabicUtils.getJuzName(juzNum),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        'ص ${ArabicUtils.toArabicDigits(startPage)}',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => widget.onPageSelected(startPage),
                    );
                  },
                ),

                // 3. Pages Grid (1..604)
                GridView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 604,
                  itemBuilder: (context, idx) {
                    final p = idx + 1;
                    final isCurrent = p == widget.currentPage;
                    return InkWell(
                      onTap: () => widget.onPageSelected(p),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.gold
                              : AppColors.gold.withOpacity(isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent ? AppColors.goldDark : AppColors.gold.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          ArabicUtils.toArabicDigits(p),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
