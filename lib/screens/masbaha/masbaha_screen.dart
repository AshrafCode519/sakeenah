import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/islamic_patterns.dart';
import '../../data/athkar_data.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/services/storage_service.dart';

class MasbahaScreen extends StatefulWidget {
  const MasbahaScreen({super.key});

  @override
  State<MasbahaScreen> createState() => _MasbahaScreenState();
}

class _MasbahaScreenState extends State<MasbahaScreen> with SingleTickerProviderStateMixin {
  int _counter = 0;
  int _target = 33;
  int _roundCount = 0;
  int _dailyTotal = 0;
  int _lifetimeTotal = 0;
  String _selectedDhikr = AthkarData.tasbihPresets[0];
  bool _vibrationEnabled = true;

  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadStoredCounts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredCounts() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _dailyTotal = storage.dailyTasbihCount;
      _lifetimeTotal = storage.totalTasbihCount;
    });
  }

  void _onTapMasbaha() async {
    _pulseController.forward().then((_) => _pulseController.reverse());
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }

    final storage = await StorageService.getInstance();
    await storage.incrementTasbih();

    setState(() {
      _counter++;
      _dailyTotal++;
      _lifetimeTotal++;

      if (_target > 0 && _counter >= _target) {
        _counter = 0;
        _roundCount++;
        HapticFeedback.vibrate();
      }
    });
  }

  void _resetCurrent() {
    setState(() {
      _counter = 0;
    });
  }

  void _showCustomDhikrDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ذكر مخصص', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'اكتب الذكر هنا...',
            hintStyle: GoogleFonts.cairo(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            child: Text('إلغاء', style: GoogleFonts.cairo()),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white)),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _selectedDhikr = controller.text.trim();
                  _counter = 0;
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _target > 0 ? (_counter / _target).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('السبحة الرقمية الذكية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_vibrationEnabled ? Icons.vibration_rounded : Icons.smartphone_rounded),
            tooltip: _vibrationEnabled ? 'تعطيل الاهتزاز' : 'تفعيل الاهتزاز',
            onPressed: () {
              setState(() {
                _vibrationEnabled = !_vibrationEnabled;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تصفير العداد الحالي',
            onPressed: _resetCurrent,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Arabesque Motif
          Positioned.fill(
            child: CustomPaint(
              painter: ArabesqueBackgroundPainter(
                primaryColor: AppColors.gold,
                opacity: isDark ? 0.03 : 0.05,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 12),
              // Dhikr Selector Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote_rounded, color: AppColors.gold, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDhikr,
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldLight : AppColors.primary,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.gold),
                      tooltip: 'اختر الذكر',
                      onSelected: (val) {
                        if (val == '__custom__') {
                          _showCustomDhikrDialog();
                        } else {
                          setState(() {
                            _selectedDhikr = val;
                            _counter = 0;
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        ...AthkarData.tasbihPresets.map(
                          (preset) => PopupMenuItem(
                            value: preset,
                            child: Text(preset, style: GoogleFonts.amiri(fontSize: 16)),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: '__custom__',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text('كتابة ذكر مخصص...', style: GoogleFonts.cairo()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Target Selector Chips (33, 99, 100, Free)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTargetChip(33, '٣٣ مرة'),
                  const SizedBox(width: 10),
                  _buildTargetChip(99, '٩٩ مرة'),
                  const SizedBox(width: 10),
                  _buildTargetChip(100, '١٠٠ مرة'),
                  const SizedBox(width: 10),
                  _buildTargetChip(0, 'حر مفتوح'),
                ],
              ),
              const Spacer(),
              // Grand Interactive Tasbih Center Clicker
              GestureDetector(
                onTap: _onTapMasbaha,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.islamicGradient,
                      border: Border.all(color: AppColors.gold, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.5),
                          blurRadius: 28,
                          spreadRadius: 4,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Circular Progress Arc
                        if (_target > 0)
                          SizedBox(
                            width: 236,
                            height: 236,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 6,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                            ),
                          ),
                        // Inner Content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ArabicUtils.toArabicDigits(_counter),
                              style: GoogleFonts.cairo(
                                fontSize: 62,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldLight,
                                height: 1.1,
                              ),
                            ),
                            if (_target > 0)
                              Text(
                                'الهدف: ${ArabicUtils.toArabicDigits(_target)}',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'انقر للتسبيح',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Statistics Footer Cards (Rounds, Today's total, Lifetime)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('الدورات المكتملة', ArabicUtils.toArabicDigits(_roundCount)),
                    Container(height: 36, width: 1, color: Colors.grey.withOpacity(0.3)),
                    _buildStatCol('تسبيح اليوم', ArabicUtils.toArabicDigits(_dailyTotal)),
                    Container(height: 36, width: 1, color: Colors.grey.withOpacity(0.3)),
                    _buildStatCol('المجموع الكلي', ArabicUtils.toArabicDigits(_lifetimeTotal)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChip(int targetValue, String label) {
    final isSelected = _target == targetValue;
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
      onSelected: (_) {
        setState(() {
          _target = targetValue;
          _counter = 0;
        });
      },
    );
  }

  Widget _buildStatCol(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
