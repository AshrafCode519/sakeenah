import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ayah_model.dart';
import '../../../models/surah_model.dart';
import '../../../core/utils/arabic_numbers.dart';

class AyahActionToolbar extends StatelessWidget {
  final AyahModel ayah;
  final SurahModel surah;
  final bool isPlaying;
  final bool isBookmarked;
  final VoidCallback onPlay;
  final VoidCallback onTafseer;
  final VoidCallback onBookmark;
  final VoidCallback onShareCard;
  final VoidCallback onCopy;
  final VoidCallback onClose;

  const AyahActionToolbar({
    super.key,
    required this.ayah,
    required this.surah,
    required this.isPlaying,
    required this.isBookmarked,
    required this.onPlay,
    required this.onTafseer,
    required this.onBookmark,
    required this.onShareCard,
    required this.onCopy,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.islamicGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Header: Verse Info & Close Button
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'سورة ${surah.name} : آية ${ArabicUtils.toArabicDigits(ayah.numberInSurah)}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ),
                    if (isBookmarked) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.bookmark_rounded, color: Colors.redAccent, size: 16),
                      Text(
                        'موضع الفاصل',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 12),
          // Actions Buttons Row
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.menu_book_rounded,
                  label: 'التفسير',
                  color: AppColors.goldLight,
                  onTap: onTafseer,
                ),
                _buildActionButton(
                  icon: isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  label: isPlaying ? 'إيقاف' : 'تلاوة',
                  color: isPlaying ? Colors.amber : Colors.white,
                  onTap: onPlay,
                ),
                _buildActionButton(
                  icon: isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
                  label: 'فاصل',
                  color: isBookmarked ? Colors.redAccent : Colors.white,
                  onTap: onBookmark,
                ),
                _buildActionButton(
                  icon: Icons.style_rounded,
                  label: 'بطاقة',
                  color: Colors.white,
                  onTap: onShareCard,
                ),
                _buildActionButton(
                  icon: Icons.copy_rounded,
                  label: 'نسخ',
                  color: Colors.white,
                  onTap: onCopy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
