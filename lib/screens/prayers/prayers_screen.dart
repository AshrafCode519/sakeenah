import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/prayer_times_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/locations_data.dart';
import '../../models/location_model.dart';
import 'widgets/country_city_picker_dialog.dart';

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  LocationModel _currentLocation = LocationsData.allLocations.first; // Default Cairo
  List<PrayerTimeItem> _prayers = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadLocationAndPrayers();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _refreshTimes();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocationAndPrayers() async {
    final storage = await StorageService.getInstance();
    final country = storage.selectedCountry;
    final city = storage.selectedCity;
    final governorate = storage.selectedGovernorate;
    final loc = LocationsData.getLocation(country, city, governorate);

    setState(() {
      _currentLocation = loc;
      _isLoading = true;
    });

    final times = await PrayerTimesService.fetchPrayerTimesWithFallback(loc);
    if (mounted) {
      setState(() {
        _prayers = times;
        _isLoading = false;
      });
    }
  }

  void _refreshTimes() {
    setState(() {
      _prayers = PrayerTimesService.getTodayPrayerTimes(location: _currentLocation);
    });
  }

  void _openLocationPicker() {
    showDialog(
      context: context,
      builder: (ctx) => CountryCityPickerDialog(
        currentLocation: _currentLocation,
        onLocationSelected: (newLoc) async {
          setState(() {
            _currentLocation = newLoc;
            _isLoading = true;
          });
          final times = await PrayerTimesService.fetchPrayerTimesWithFallback(newLoc);
          if (mounted) {
            setState(() {
              _prayers = times;
              _isLoading = false;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final hijri = PrayerTimesService.getApproximateHijriDate(now);
    final nextPrayer = _prayers.isNotEmpty
        ? _prayers.firstWhere((p) => p.isNext, orElse: () => _prayers.first)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('مواقيت الصلاة والقبلة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_rounded, color: AppColors.goldLight),
            tooltip: 'تغيير المحافظة والمدينة',
            onPressed: _openLocationPicker,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // Quick Governorate Switcher Banner (اختيار المحافظة لتوقيت صحيح 100%)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.location_on_rounded, color: AppColors.gold, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'المحافظة المحددة للمواقيت:',
                                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      _currentLocation.displayName,
                                      style: GoogleFonts.cairo(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.goldLight : AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openLocationPicker,
                          icon: const Icon(Icons.tune_rounded, size: 15),
                          label: Text(
                            'تغيير المحافظة',
                            style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            backgroundColor: AppColors.gold.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top Hero Card: Next Prayer & Countdown
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppColors.islamicGradient,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Hijri Date & Clickable Location Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hijri,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: AppColors.goldLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: _openLocationPicker,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: AppColors.gold, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_currentLocation.shortDisplayName} ▾',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'الصلاة القادمة',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextPrayer?.nameArabic ?? 'الفَجْر',
                          style: GoogleFonts.cairo(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextPrayer?.formattedTime ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Method note
                        Text(
                          'الحساب: ${_currentLocation.methodName}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.goldLight.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Daily Prayer Times List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _prayers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = _prayers[index];
                      final isNext = p.isNext;

                      IconData getPrayerIcon(String name) {
                        if (name.contains('الفجر')) return Icons.wb_twilight_rounded;
                        if (name.contains('الشروق')) return Icons.wb_sunny_outlined;
                        if (name.contains('الظهر')) return Icons.wb_sunny_rounded;
                        if (name.contains('العصر')) return Icons.cloud_outlined;
                        if (name.contains('المغرب')) return Icons.nights_stay_outlined;
                        return Icons.bedtime_rounded;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isNext
                              ? AppColors.primary.withOpacity(isDark ? 0.3 : 0.1)
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isNext ? AppColors.gold : AppColors.gold.withOpacity(0.2),
                            width: isNext ? 1.8 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isNext ? AppColors.gold : AppColors.primary).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    getPrayerIcon(p.nameArabic),
                                    color: isNext ? AppColors.gold : AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nameArabic,
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      p.nameEnglish,
                                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (isNext)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'الصلاة القادمة',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.goldDark,
                                      ),
                                    ),
                                  ),
                                Text(
                                  p.formattedTime,
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isNext ? AppColors.gold : (isDark ? Colors.white : AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Qibla Direction Compass Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.explore_rounded, color: AppColors.gold, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'بوصلة اتجاه القبلة',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.goldLight : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 2),
                            gradient: RadialGradient(
                              colors: [
                                AppColors.gold.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: -0.4,
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  size: 56,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                child: Text(
                                  'الكعبة المشرفة',
                                  style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.gold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'الاتجاه المباشر للقبلة من مدينة ${_currentLocation.city}',
                          style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
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
