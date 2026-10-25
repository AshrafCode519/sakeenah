import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/theme/islamic_patterns.dart';
import '../../models/surah_model.dart';
import '../../models/ayah_model.dart';
import '../../data/quran_data.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/storage_service.dart';
import 'widgets/ayah_mushaf_view.dart';
import 'widgets/ayah_action_toolbar.dart';
import 'widgets/mushaf_tafseer_sheet.dart';
import 'ayah_card_screen.dart';

/// Single Mushaf Page Data Representation
class MushafPageData {
  final int pageNumber;
  final int juzNumber;
  final List<AyahModel> ayahs;
  final bool hasSurahHeader;

  const MushafPageData({
    required this.pageNumber,
    required this.juzNumber,
    required this.ayahs,
    required this.hasSurahHeader,
  });
}

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
  double _fontSize = 24.0;
  List<AyahModel> _ayahs = [];
  List<MushafPageData> _pages = [];
  bool _isLoading = true;
  AyahModel? _selectedAyah;
  int? _bookmarkAyahNumber;
  int? _activePlayingAyah;
  bool _isMushafPageView = true; // true = PageView flipping like Ayah app, false = List view

  late PageController _pageController;
  int _currentPageIndex = 0;

  final QuranAudioService _audioService = QuranAudioService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadBookmark();
    _loadSurahAyahs();
    _audioService.currentAyahPlaying.addListener(_onAudioAyahChanged);
  }

  @override
  void dispose() {
    _audioService.currentAyahPlaying.removeListener(_onAudioAyahChanged);
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAudioAyahChanged() {
    if (mounted) {
      final active = _audioService.currentAyahPlaying.value;
      setState(() {
        _activePlayingAyah = active;
      });

      // Auto-flip page if active ayah is on another page
      if (active != null && _pages.isNotEmpty && _pageController.hasClients) {
        final pageIdx = _pages.indexWhere((p) => p.ayahs.any((a) => a.number == active));
        if (pageIdx != -1 && pageIdx != _currentPageIndex) {
          _pageController.animateToPage(
            pageIdx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  Future<void> _loadBookmark() async {
    final storage = await StorageService.getInstance();
    if (storage.bookmarkSurah == widget.surah.number) {
      setState(() {
        _bookmarkAyahNumber = storage.bookmarkAyah;
      });
    }
  }

  /// Groups ayahs into authentic Mushaf Pages (like Ayah app)
  List<MushafPageData> _buildPages(List<AyahModel> ayahs) {
    if (ayahs.isEmpty) return [];

    // 1. Group by Medina Mushaf standard page numbers if available
    final uniquePages = ayahs.map((a) => a.page).where((p) => p > 0).toSet();
    if (uniquePages.length > 1 || (uniquePages.length == 1 && uniquePages.first > 1)) {
      final Map<int, List<AyahModel>> pageMap = {};
      for (final a in ayahs) {
        pageMap.putIfAbsent(a.page, () => []).add(a);
      }
      return pageMap.entries.map((e) {
        return MushafPageData(
          pageNumber: e.key,
          juzNumber: e.value.first.juz,
          ayahs: e.value,
          hasSurahHeader: e.value.any((a) => a.numberInSurah == 1),
        );
      }).toList();
    }

    // 2. Fallback: chunk into pages of 7-8 verses per page
    const int pageSize = 7;
    final List<MushafPageData> list = [];
    for (int i = 0; i < ayahs.length; i += pageSize) {
      final chunk = ayahs.sublist(i, (i + pageSize).clamp(0, ayahs.length));
      final pageNum = widget.surah.startPage + (i ~/ pageSize);
      list.add(MushafPageData(
        pageNumber: pageNum,
        juzNumber: chunk.first.juz,
        ayahs: chunk,
        hasSurahHeader: chunk.any((a) => a.numberInSurah == 1),
      ));
    }
    return list;
  }

  Future<void> _loadSurahAyahs() async {
    // 1. Check local pre-bundled surahs first (instant 0ms offline load)
    final cached = QuranData.builtInSurahs[widget.surah.number];
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _ayahs = cached;
        _pages = _buildPages(cached);
        _isLoading = false;
      });
      _jumpToInitialAyahPage();

      // If cached covers full surah, return immediately
      if (cached.length >= widget.surah.numberOfAyahs) {
        return;
      }
    }

    // 2. Fetch full surah from trusted Quran API asynchronously (with fallback)
    try {
      final url = Uri.parse('https://api.alquran.cloud/v1/surah/${widget.surah.number}/editions/quran-uthmani,ar.muyassar');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
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
            audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${u['number']}.mp3',
          ));
        }

        if (mounted) {
          setState(() {
            _ayahs = fetchedList;
            _pages = _buildPages(fetchedList);
            _isLoading = false;
          });
          _jumpToInitialAyahPage();
          return;
        }
      }
    } catch (_) {
      // If already displayed from cached, keep it
      if (_ayahs.isNotEmpty) return;
    }

    if (mounted) {
      setState(() {
        _ayahs = List.generate(
          widget.surah.numberOfAyahs,
          (i) => AyahModel(
            number: widget.surah.number * 100 + (i + 1),
            numberInSurah: i + 1,
            surahNumber: widget.surah.number,
            page: widget.surah.startPage + (i ~/ 7),
            text: 'آية رقم ${ArabicUtils.toArabicDigits(i + 1)} من سورة ${widget.surah.name} المباركة',
            tafseer: 'تفسير ميسر ومختصر للآية الكريمة رقم ${ArabicUtils.toArabicDigits(i + 1)} من سورة ${widget.surah.name}.',
          ),
        );
        _pages = _buildPages(_ayahs);
        _isLoading = false;
      });
      _jumpToInitialAyahPage();
    }
  }

  void _jumpToInitialAyahPage() {
    final targetAyah = _bookmarkAyahNumber ?? widget.initialAyah;
    if (targetAyah > 1 && _pages.isNotEmpty) {
      final idx = _pages.indexWhere((p) => p.ayahs.any((a) => a.numberInSurah == targetAyah));
      if (idx != -1 && idx != _currentPageIndex) {
        _currentPageIndex = idx;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(idx);
          }
        });
      }
    }
  }

  void _onAyahTap(AyahModel ayah) {
    setState(() {
      if (_selectedAyah?.numberInSurah == ayah.numberInSurah) {
        _selectedAyah = null; // Toggle off if clicked again
      } else {
        _selectedAyah = ayah; // Highlight verse and show toolbar
      }
    });
  }

  void _goToNextPage() {
    if (_currentPageIndex < _pages.length - 1 && _pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0 && _pageController.hasClients) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MushafTafseerSheet(ayah: ayah, surah: widget.surah),
    );
  }

  void _setBookmark(AyahModel ayah) async {
    final storage = await StorageService.getInstance();
    await storage.saveBookmark(
      surah: widget.surah.number,
      ayah: ayah.numberInSurah,
      page: ayah.page,
    );
    setState(() {
      _bookmarkAyahNumber = ayah.numberInSurah;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ الفاصل عند الآية (${ArabicUtils.toArabicDigits(ayah.numberInSurah)}) بنجاح',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAyahCard(AyahModel ayah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AyahCardScreen(ayah: ayah, surah: widget.surah),
      ),
    );
  }

  void _copyAyah(AyahModel ayah) {
    Clipboard.setData(ClipboardData(
      text: '﴿${ayah.text}﴾ [سورة ${widget.surah.name}: ${ayah.numberInSurah}]',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'سُورَةُ ${widget.surah.name}',
              style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (_pages.isNotEmpty && _currentPageIndex < _pages.length)
              Text(
                'الجزء ${_pages[_currentPageIndex].juzNumber} • صفحة ${_pages[_currentPageIndex].pageNumber}',
                style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white70 : AppColors.goldLight),
              ),
          ],
        ),
        actions: [
          // Switch between Ayah app page-flip view and list view
          IconButton(
            icon: Icon(_isMushafPageView ? Icons.view_headline_rounded : Icons.auto_stories_rounded),
            tooltip: _isMushafPageView ? 'عرض البطاقات المنفصلة' : 'طريقة تقليب الصفحات (تطبيق آية)',
            onPressed: () {
              setState(() {
                _isMushafPageView = !_isMushafPageView;
                _selectedAyah = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded),
            tooltip: 'تكبير الخط',
            onPressed: () {
              setState(() {
                if (_fontSize < 38) _fontSize += 2;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded),
            tooltip: 'تصغير الخط',
            onPressed: () {
              setState(() {
                if (_fontSize > 18) _fontSize -= 2;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                // Background Arabesque Motif
                Positioned.fill(
                  child: CustomPaint(
                    painter: ArabesqueBackgroundPainter(
                      primaryColor: AppColors.gold,
                      opacity: isDark ? 0.03 : 0.04,
                    ),
                  ),
                ),

                // Main Quran Reader Content
                GestureDetector(
                  onTap: () {
                    // Deselect when tapping blank area
                    if (_selectedAyah != null) {
                      setState(() => _selectedAyah = null);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(bottom: _selectedAyah != null ? 80 : 0),
                    child: _isMushafPageView ? _buildMushafPageView(context) : _buildCardListView(context),
                  ),
                ),

                // Floating Action Toolbar (طريقة تطبيق آية عند تحديد آية)
                if (_selectedAyah != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AyahActionToolbar(
                      ayah: _selectedAyah!,
                      surah: widget.surah,
                      isPlaying: _activePlayingAyah == _selectedAyah!.number,
                      isBookmarked: _bookmarkAyahNumber == _selectedAyah!.numberInSurah,
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

  /// Authentic Mushaf PageView with Horizontal Page-by-Page Flipping (مثل تطبيق آية)
  Widget _buildMushafPageView(BuildContext context) {
    if (_pages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final pageData = _pages[index];
          return AyahMushafView(
            surah: widget.surah,
            ayahs: pageData.ayahs,
            pageNumber: pageData.pageNumber,
            juzNumber: pageData.juzNumber,
            showSurahHeader: pageData.hasSurahHeader,
            showBasmalah: pageData.hasSurahHeader && widget.surah.number != 9 && widget.surah.number != 1,
            selectedAyahNumberInSurah: _selectedAyah?.numberInSurah,
            bookmarkAyahNumberInSurah: _bookmarkAyahNumber,
            playingAyahGlobalNumber: _activePlayingAyah,
            fontSize: _fontSize,
            onAyahSelected: _onAyahTap,
            onNextPage: _goToNextPage,
            onPreviousPage: _goToPreviousPage,
            hasNextPage: index < _pages.length - 1,
            hasPreviousPage: index > 0,
          );
        },
      ),
    );
  }

  /// Optional Card List View
  Widget _buildCardListView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 12, bottom: 90, left: 16, right: 16),
      child: Column(
        children: _ayahs.map((ayah) {
          final isPlayingThis = (_activePlayingAyah == ayah.number);
          final isSelected = (_selectedAyah?.numberInSurah == ayah.numberInSurah);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPlayingThis
                  ? AppColors.gold.withOpacity(0.18)
                  : (isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : (isDark ? AppColors.darkCard : Colors.white)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isPlayingThis || isSelected)
                    ? AppColors.gold
                    : AppColors.gold.withOpacity(0.15),
                width: (isPlayingThis || isSelected) ? 1.8 : 1.0,
              ),
            ),
            child: InkWell(
              onTap: () => _onAyahTap(ayah),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'آية ${ArabicUtils.toArabicDigits(ayah.numberInSurah)}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.goldLight : AppColors.goldDark,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isPlayingThis ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                              color: isPlayingThis ? AppColors.gold : AppColors.primary,
                            ),
                            onPressed: () => _playRecitation(ayah),
                          ),
                          IconButton(
                            icon: const Icon(Icons.menu_book_rounded, color: AppColors.goldDark),
                            onPressed: () => _openTafseer(ayah),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ayah.text,
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textDark,
                      height: 2.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
