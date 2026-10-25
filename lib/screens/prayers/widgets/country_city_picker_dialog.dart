import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/islamic_patterns.dart';
import '../../../data/locations_data.dart';
import '../../../models/location_model.dart';
import '../../../core/services/storage_service.dart';

class CountryCityPickerDialog extends StatefulWidget {
  final LocationModel currentLocation;
  final Function(LocationModel selectedLocation) onLocationSelected;

  const CountryCityPickerDialog({
    super.key,
    required this.currentLocation,
    required this.onLocationSelected,
  });

  @override
  State<CountryCityPickerDialog> createState() => _CountryCityPickerDialogState();
}

class _CountryCityPickerDialogState extends State<CountryCityPickerDialog> {
  late String _selectedCountry;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.currentLocation.country;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countries = LocationsData.availableCountries;
    final locations = LocationsData.getLocationsForCountry(_selectedCountry).where((loc) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final cityMatch = loc.city.toLowerCase().contains(q);
      final govMatch = (loc.governorate ?? '').toLowerCase().contains(q);
      final countryMatch = loc.country.toLowerCase().contains(q);
      return cityMatch || govMatch || countryMatch;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Title, Islamic Star & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(
                        painter: IslamicStarPainter(color: AppColors.gold, strokeWidth: 1.2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'تحديد المحافظة والمدينة للمواقيت',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldLight : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'ابحث باسم المحافظة أو المدينة (مثال: الدقهلية، المنصورة، طنطا)...',
                hintStyle: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold, size: 20),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.parchment,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.gold.withOpacity(0.2)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Country Horizontal Selector Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: countries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final country = countries[index];
                  final isSelected = country == _selectedCountry;
                  return ChoiceChip(
                    label: Text(
                      country,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textDark),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (_) {
                      setState(() {
                        _selectedCountry = country;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Info Banner for Egyptian Governorates
            if (_selectedCountry == 'مصر')
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.gold, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'تشمل جميع محافظات مصر الـ 27 بالتوقيت الدقيق لهيئة المساحة المصرية',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.goldLight : AppColors.goldDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),

            // Governorates & Cities List
            Expanded(
              child: locations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'لا توجد محافظة أو مدينة مطابقة لبحثك',
                          style: GoogleFonts.cairo(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: locations.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      ),
                      itemBuilder: (context, index) {
                        final loc = locations[index];
                        final isCurrent = loc.country == widget.currentLocation.country &&
                            (loc.city == widget.currentLocation.city ||
                             (loc.governorate != null && loc.governorate == widget.currentLocation.governorate));

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.success.withOpacity(0.15)
                                  : AppColors.gold.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCurrent ? Icons.check_circle_rounded : Icons.location_on_rounded,
                              color: isCurrent ? AppColors.success : AppColors.gold,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            loc.shortDisplayName,
                            style: GoogleFonts.cairo(
                              fontSize: 14.5,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              color: isCurrent ? AppColors.primaryAccent : (isDark ? Colors.white : AppColors.textDark),
                            ),
                          ),
                          subtitle: Text(
                            '${loc.methodName} • خط عرض ${loc.latitude.toStringAsFixed(2)}°',
                            style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                          ),
                          trailing: isCurrent
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'المحددة حالياً',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                          onTap: () async {
                            final storage = await StorageService.getInstance();
                            await storage.setPrayerLocation(loc.country, loc.city, loc.governorate);
                            widget.onLocationSelected(loc);
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
