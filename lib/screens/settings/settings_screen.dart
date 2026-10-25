import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/audio_service.dart';
import '../../data/locations_data.dart';
import '../../models/location_model.dart';
import '../prayers/widgets/country_city_picker_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool isDark)? onThemeChanged;

  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = false;
  bool _floatingAthkar = true;
  int _floatingInterval = 15;
  String _selectedReciter = 'ar.alafasy';
  LocationModel _currentLocation = LocationsData.allLocations.first;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = await StorageService.getInstance();
    final country = storage.selectedCountry;
    final city = storage.selectedCity;
    final governorate = storage.selectedGovernorate;
    setState(() {
      _isDark = storage.isDarkMode;
      _floatingAthkar = storage.floatingAthkarEnabled;
      _floatingInterval = storage.floatingIntervalMinutes;
      _selectedReciter = QuranAudioService().selectedReciter;
      _currentLocation = LocationsData.getLocation(country, city, governorate);
    });
  }

  void _openLocationPicker() {
    showDialog(
      context: context,
      builder: (ctx) => CountryCityPickerDialog(
        currentLocation: _currentLocation,
        onLocationSelected: (newLoc) {
          setState(() {
            _currentLocation = newLoc;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات والخيارات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Section: General & Appearance
          Text(
            'المظهر والهوية',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                  title: Text('الوضع الليلي الحقيقي', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                  subtitle: Text('ألوان هادئة للعين أثناء القراءة ليلاً', style: GoogleFonts.cairo(fontSize: 12)),
                  value: _isDark,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    setState(() => _isDark = val);
                    final storage = await StorageService.getInstance();
                    await storage.setDarkMode(val);
                    widget.onThemeChanged?.call(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Section: Prayer Location
          Text(
            'مواقيت الصلاة والدولة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.location_on_rounded, color: AppColors.primary),
              title: Text(
                '${_currentLocation.city}، ${_currentLocation.country}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'طريقة الحساب: ${_currentLocation.methodName}',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: _openLocationPicker,
            ),
          ),
          const SizedBox(height: 20),
          // Section: Reciter Selection
          Text(
            'القارئ والتلاوات',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text('اختيار القارئ الافتراضي:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedReciter,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.parchment,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: QuranAudioService.availableReciters.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, style: GoogleFonts.cairo(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedReciter = val);
                        QuranAudioService().selectedReciter = val;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Section: Floating Athkar Notifications
          Text(
            'نظام الأذكار التلقائي (الظهور المنبثق)',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                  title: Text('شريط الأذكار والتنبيهات الدورية', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                  subtitle: Text('عرض أذكار خفيفة دون مقاطعة العمل', style: GoogleFonts.cairo(fontSize: 12)),
                  value: _floatingAthkar,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    setState(() => _floatingAthkar = val);
                    final storage = await StorageService.getInstance();
                    await storage.setFloatingAthkarEnabled(val);
                  },
                ),
                if (_floatingAthkar) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تكرار الظهور: كل $_floatingInterval دقيقة',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          value: _floatingInterval.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: '$_floatingInterval دقيقة',
                          activeColor: AppColors.primary,
                          onChanged: (val) async {
                            final intVal = val.round();
                            setState(() => _floatingInterval = intVal);
                            final storage = await StorageService.getInstance();
                            await storage.setFloatingInterval(intVal);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Section: Reset Khatmah
          Text(
            'إدارة الختمة والبيانات',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.restore_page_rounded, color: AppColors.warning),
              title: Text('بدء ختمة جديدة من البداية', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              subtitle: Text('إعادة ضبط علامة القراءة لسورة الفاتحة الآية ١', style: GoogleFonts.cairo(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('تأكيد بدء ختمة جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    content: Text(
                      'هل أنت متأكد من رغبتك في إعادة موضع الختمة إلى بداية المصحف الشريف؟',
                      style: GoogleFonts.cairo(),
                    ),
                    actions: [
                      TextButton(
                        child: Text('إلغاء', style: GoogleFonts.cairo()),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: Text('نعم، ابدأ', style: GoogleFonts.cairo(color: Colors.white)),
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final storage = await StorageService.getInstance();
                  await storage.saveBookmark(surah: 1, ayah: 1, page: 1);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إعادة ضبط الختمة بنجاح، جعلها الله مباركة.', style: GoogleFonts.cairo()),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 28),
          // App About Card with Islamic Motif
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.islamicGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text(
                  'تطبيق سَكينة • بيان',
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'المصحف الشريف الذكي والأذكار العائمة متعدد المنصات\nصدقة جارية، لا تنسونا ووالدينا من صالح دعائكم',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'الإصدار 1.0.0 (Windows & Cross-Platform)',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: AppColors.goldLight.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
