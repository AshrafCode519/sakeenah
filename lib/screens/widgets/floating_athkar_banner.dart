import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/athkar_data.dart';

class FloatingAthkarBanner extends StatefulWidget {
  final VoidCallback? onClose;

  const FloatingAthkarBanner({super.key, this.onClose});

  @override
  State<FloatingAthkarBanner> createState() => _FloatingAthkarBannerState();
}

class _FloatingAthkarBannerState extends State<FloatingAthkarBanner> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-cycle dhikr every 25 seconds
    _timer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % AthkarData.floatingAthkar.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextDhikr() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % AthkarData.floatingAthkar.length;
    });
  }

  void _copyDhikr() {
    final text = AthkarData.floatingAthkar[_currentIndex];
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الذكر إلى الحافظة', style: GoogleFonts.cairo()),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dhikrText = AthkarData.floatingAthkar[_currentIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF132A22), const Color(0xFF0F1E19)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryAccent.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryAccent.withOpacity(0.18),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: _nextDhikr,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  dhikrText,
                  key: ValueKey<int>(_currentIndex),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldLight : AppColors.primaryDark,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.gold),
            tooltip: 'نسخ الذكر',
            onPressed: _copyDhikr,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            tooltip: 'الذكر التالي',
            onPressed: _nextDhikr,
          ),
        ],
      ),
    );
  }
}
