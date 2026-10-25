import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // --- Khatmah & Reading Bookmark ---
  int get bookmarkSurah => _prefs?.getInt('bookmark_surah') ?? 1;
  int get bookmarkAyah => _prefs?.getInt('bookmark_ayah') ?? 1;
  int get bookmarkPage => _prefs?.getInt('bookmark_page') ?? 1;

  Future<void> saveBookmark({required int surah, required int ayah, int page = 1}) async {
    await _prefs?.setInt('bookmark_surah', surah);
    await _prefs?.setInt('bookmark_ayah', ayah);
    await _prefs?.setInt('bookmark_page', page);
  }

  // --- Tasbih / Masbaha ---
  int get totalTasbihCount => _prefs?.getInt('total_tasbih_count') ?? 0;
  int get dailyTasbihCount => _prefs?.getInt('daily_tasbih_count') ?? 0;

  Future<void> incrementTasbih() async {
    final total = totalTasbihCount + 1;
    final daily = dailyTasbihCount + 1;
    await _prefs?.setInt('total_tasbih_count', total);
    await _prefs?.setInt('daily_tasbih_count', daily);
  }

  Future<void> resetDailyTasbih() async {
    await _prefs?.setInt('daily_tasbih_count', 0);
  }

  // --- Daily Wird Rings Tracker ---
  bool get morningWirdDone => _prefs?.getBool('wird_morning_${_todayKey()}') ?? false;
  bool get eveningWirdDone => _prefs?.getBool('wird_evening_${_todayKey()}') ?? false;
  int get dailyQuranPages => _prefs?.getInt('wird_quran_${_todayKey()}') ?? 0;

  Future<void> setMorningWirdDone(bool value) async {
    await _prefs?.setBool('wird_morning_${_todayKey()}', value);
  }

  Future<void> setEveningWirdDone(bool value) async {
    await _prefs?.setBool('wird_evening_${_todayKey()}', value);
  }

  Future<void> addDailyQuranPage() async {
    final current = dailyQuranPages;
    await _prefs?.setInt('wird_quran_${_todayKey()}', current + 1);
  }

  // --- Floating Athkar Settings ---
  bool get floatingAthkarEnabled => _prefs?.getBool('floating_athkar_enabled') ?? true;

  // --- Country, Governorate & City for Prayer Times ---
  String get selectedCountry => _prefs?.getString('prayer_country') ?? 'مصر';
  String get selectedCity => _prefs?.getString('prayer_city') ?? 'القاهرة';
  String? get selectedGovernorate => _prefs?.getString('prayer_governorate');

  Future<void> setPrayerLocation(String country, String city, [String? governorate]) async {
    await _prefs?.setString('prayer_country', country);
    await _prefs?.setString('prayer_city', city);
    if (governorate != null) {
      await _prefs?.setString('prayer_governorate', governorate);
    } else {
      await _prefs?.remove('prayer_governorate');
    }
  }
  int get floatingIntervalMinutes => _prefs?.getInt('floating_interval_minutes') ?? 15;

  Future<void> setFloatingAthkarEnabled(bool value) async {
    await _prefs?.setBool('floating_athkar_enabled', value);
  }

  Future<void> setFloatingInterval(int minutes) async {
    await _prefs?.setInt('floating_interval_minutes', minutes);
  }

  // --- Theme Mode ---
  bool get isDarkMode => _prefs?.getBool('is_dark_mode') ?? false;
  Future<void> setDarkMode(bool isDark) async {
    await _prefs?.setBool('is_dark_mode', isDark);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
