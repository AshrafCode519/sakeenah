import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/dhikr_model.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/services/storage_service.dart';

class AthkarReaderScreen extends StatefulWidget {
  final String title;
  final List<DhikrModel> athkarList;
  final String categoryKey; // 'morning', 'evening', etc.

  const AthkarReaderScreen({
    super.key,
    required this.title,
    required this.athkarList,
    required this.categoryKey,
  });

  @override
  State<AthkarReaderScreen> createState() => _AthkarReaderScreenState();
}

class _AthkarReaderScreenState extends State<AthkarReaderScreen> {
  late List<DhikrModel> _list;

  @override
  void initState() {
    super.initState();
    _list = widget.athkarList;
  }

  void _incrementDhikr(int index) async {
    HapticFeedback.lightImpact();
    setState(() {
      _list[index].increment();
    });

    // Check if all are completed
    final allDone = _list.every((d) => d.isCompleted);
    if (allDone) {
      final storage = await StorageService.getInstance();
      if (widget.categoryKey == 'morning') {
        await storage.setMorningWirdDone(true);
      } else if (widget.categoryKey == 'evening') {
        await storage.setEveningWirdDone(true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'هنيئاً لك! أتممت ${widget.title} وكتب الله لك الأجر والحفظ.',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _resetAll() {
    setState(() {
      for (var d in _list) {
        d.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = _list.where((d) => d.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة تصفير العدادات',
            onPressed: _resetAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.gold.withOpacity(0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'أنجزت ${ArabicUtils.toArabicDigits(completedCount)} من ${ArabicUtils.toArabicDigits(_list.length)} أذكار',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _list.isNotEmpty ? completedCount / _list.length : 0.0,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dhikr Cards List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final dhikr = _list[index];
                return _buildDhikrCard(context, dhikr, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrCard(BuildContext context, DhikrModel dhikr, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = dhikr.isCompleted;

    String repeatLabel;
    if (dhikr.targetCount == 1) {
      repeatLabel = 'مرة واحدة';
    } else if (dhikr.targetCount == 3) {
      repeatLabel = '٣ مرات';
    } else if (dhikr.targetCount == 4) {
      repeatLabel = '٤ مرات';
    } else if (dhikr.targetCount == 7) {
      repeatLabel = '٧ مرات';
    } else if (dhikr.targetCount == 10) {
      repeatLabel = '١٠ مرات';
    } else {
      repeatLabel = '${ArabicUtils.toArabicDigits(dhikr.targetCount)} مرة';
    }

    return Card(
      elevation: isDone ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDone ? AppColors.success.withOpacity(0.5) : AppColors.gold.withOpacity(0.25),
          width: isDone ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isDone ? null : () => _incrementDhikr(index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Dhikr Index, Repeat Badge & Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'الذكر ${ArabicUtils.toArabicDigits(index + 1)} من ${ArabicUtils.toArabicDigits(_list.length)}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: Text(
                      repeatLabel,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldLight : AppColors.goldDark,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: AppColors.gold,
                    tooltip: 'نسخ الذكر',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: dhikr.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم نسخ الذكر المبارك إلى الحافظة',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  if (dhikr.currentCount > 0 && !isDone) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      color: Colors.grey,
                      tooltip: 'إعادة تصفير هذا الذكر',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          dhikr.reset();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dhikr Text
                  Text(
                    dhikr.text,
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                      height: 1.9,
                    ),
                  ),
                  if (dhikr.benefit.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(isDark ? 0.08 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.gold, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dhikr.benefit,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? AppColors.goldLight : AppColors.goldDark,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (dhikr.source.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'المصدر: ${dhikr.source}',
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),

            // Linear mini-progress for the single dhikr
            if (dhikr.targetCount > 1)
              ClipRRect(
                child: LinearProgressIndicator(
                  value: dhikr.progress,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? AppColors.success : AppColors.gold,
                  ),
                  minHeight: 4,
                ),
              ),

            // Interactive Counter Button Area
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDone ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                    color: isDone ? AppColors.success : AppColors.goldLight,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isDone
                        ? 'اكتمل الذكر بفضل الله'
                        : 'انقر للعد: ${ArabicUtils.toArabicDigits(dhikr.currentCount)} / ${ArabicUtils.toArabicDigits(dhikr.targetCount)}',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDone ? AppColors.success : AppColors.goldLight,
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
