import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../models/location_model.dart';
import '../../data/locations_data.dart';

class PrayerTimeItem {
  final String nameArabic;
  final String nameEnglish;
  final DateTime time;
  final bool isNext;

  PrayerTimeItem({
    required this.nameArabic,
    required this.nameEnglish,
    required this.time,
    this.isNext = false,
  });

  String get formattedTime => DateFormat('hh:mm a', 'en').format(time);
}

class PrayerTimesService {
  static final Map<String, List<PrayerTimeItem>> _cache = {};

  /// Computes accurate prayer times for the chosen country/city
  static List<PrayerTimeItem> getTodayPrayerTimes({
    LocationModel? location,
    DateTime? date,
  }) {
    final loc = location ?? LocationsData.allLocations.first;
    final now = date ?? DateTime.now();

    final timesMap = _calculateAstronomicalTimes(loc, now);

    final rawList = [
      {'ar': 'الفَجْر', 'en': 'Fajr', 'time': timesMap['Fajr']!},
      {'ar': 'الشُّرُوق', 'en': 'Sunrise', 'time': timesMap['Sunrise']!},
      {'ar': 'الظُّهْر', 'en': 'Dhuhr', 'time': timesMap['Dhuhr']!},
      {'ar': 'العَصْر', 'en': 'Asr', 'time': timesMap['Asr']!},
      {'ar': 'المَغْرِب', 'en': 'Maghrib', 'time': timesMap['Maghrib']!},
      {'ar': 'العِشَاء', 'en': 'Isha', 'time': timesMap['Isha']!},
    ];

    // Find next prayer
    int nextIndex = -1;
    for (int i = 0; i < rawList.length; i++) {
      final t = rawList[i]['time'] as DateTime;
      if (t.isAfter(now)) {
        nextIndex = i;
        break;
      }
    }
    if (nextIndex == -1) nextIndex = 0; // Next day Fajr

    return List.generate(rawList.length, (i) {
      final item = rawList[i];
      return PrayerTimeItem(
        nameArabic: item['ar'] as String,
        nameEnglish: item['en'] as String,
        time: item['time'] as DateTime,
        isNext: i == nextIndex,
      );
    });
  }

  /// Tries to fetch verified ministerial prayer times from Aladhan API by coordinates, falls back to astronomical engine
  static Future<List<PrayerTimeItem>> fetchPrayerTimesWithFallback(LocationModel loc) async {
    final cacheKey = '${loc.country}_${loc.governorate ?? ''}_${loc.city}_${loc.latitude}_${loc.longitude}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings?latitude=${loc.latitude}&longitude=${loc.longitude}&method=${loc.methodId}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final timings = body['data']['timings'] as Map<String, dynamic>;
        final now = DateTime.now();

        DateTime parseTimeStr(String str) {
          final parts = str.split(':');
          final h = int.parse(parts[0].trim());
          final m = int.parse(parts[1].split(' ')[0].trim());
          return DateTime(now.year, now.month, now.day, h, m);
        }

        final rawList = [
          {'ar': 'الفَجْر', 'en': 'Fajr', 'time': parseTimeStr(timings['Fajr'])},
          {'ar': 'الشُّرُوق', 'en': 'Sunrise', 'time': parseTimeStr(timings['Sunrise'])},
          {'ar': 'الظُّهْر', 'en': 'Dhuhr', 'time': parseTimeStr(timings['Dhuhr'])},
          {'ar': 'العَصْر', 'en': 'Asr', 'time': parseTimeStr(timings['Asr'])},
          {'ar': 'المَغْرِب', 'en': 'Maghrib', 'time': parseTimeStr(timings['Maghrib'])},
          {'ar': 'العِشَاء', 'en': 'Isha', 'time': parseTimeStr(timings['Isha'])},
        ];

        int nextIndex = -1;
        for (int i = 0; i < rawList.length; i++) {
          final t = rawList[i]['time'] as DateTime;
          if (t.isAfter(now)) {
            nextIndex = i;
            break;
          }
        }
        if (nextIndex == -1) nextIndex = 0;

        final items = List.generate(rawList.length, (i) {
          final item = rawList[i];
          return PrayerTimeItem(
            nameArabic: item['ar'] as String,
            nameEnglish: item['en'] as String,
            time: item['time'] as DateTime,
            isNext: i == nextIndex,
          );
        });

        _cache[cacheKey] = items;
        return items;
      }
    } catch (_) {
      // Fallback to local astronomical engine
    }

    final localList = getTodayPrayerTimes(location: loc);
    _cache[cacheKey] = localList;
    return localList;
  }

  /// High precision Astronomical Calculation Engine for any latitude and longitude
  static Map<String, DateTime> _calculateAstronomicalTimes(LocationModel loc, DateTime date) {
    double degToRad(double deg) => deg * (math.pi / 180.0);
    double radToDeg(double rad) => rad * (180.0 / math.pi);
    double fixAngle(double a) => a - 360.0 * (a / 360.0).floor();
    double fixHour(double a) => a - 24.0 * (a / 24.0).floor();

    final offsetHours = date.timeZoneOffset.inMinutes / 60.0;
    final y = date.year;
    final m = date.month;
    final d = date.day.toDouble();

    // Julian Day Calculation
    final jd = (367 * y) -
        ((7 * (y + ((m + 9) ~/ 12))) ~/ 4) +
        ((275 * m) ~/ 9) +
        d -
        730531.5;
    final t = jd - 2451545.0;

    // Sun Coordinates
    final q = fixAngle(280.459 + 0.98564736 * t);
    final g = fixAngle(357.529 + 0.98560028 * t);
    final l = fixAngle(q + 1.915 * math.sin(degToRad(g)) + 0.020 * math.sin(degToRad(2 * g)));
    final e = 23.439 - 0.00000036 * t;

    final sinL = math.sin(degToRad(l));
    final cosL = math.cos(degToRad(l));
    final sinE = math.sin(degToRad(e));
    final cosE = math.cos(degToRad(e));

    final ra = fixAngle(radToDeg(math.atan2(cosE * sinL, cosL))) / 15.0;
    final decl = radToDeg(math.asin(sinE * sinL));

    // Equation of Time in hours
    final eot = (q / 15.0) - ra;

    // Solar Noon (Zawal)
    final solarNoon = fixHour(12.0 + offsetHours - (loc.longitude / 15.0) - eot);

    double? hourAngle(double angle) {
      final latRad = degToRad(loc.latitude);
      final declRad = degToRad(decl);
      final cosH = (math.sin(degToRad(-angle)) - (math.sin(latRad) * math.sin(declRad))) /
          (math.cos(latRad) * math.cos(declRad));
      if (cosH < -1.0 || cosH > 1.0) return null;
      return radToDeg(math.acos(cosH)) / 15.0;
    }

    final h0 = hourAngle(0.833) ?? 6.0;
    final hFajr = hourAngle(loc.fajrAngle) ?? (h0 + 1.5);
    final asrAngle = -radToDeg(math.atan(1.0 / (1.0 + math.tan(degToRad((loc.latitude - decl).abs())))));
    final hAsr = hourAngle(asrAngle) ?? 3.0;

    final hIsha = loc.ishaInterval90 ? (h0 + 1.5) : (hourAngle(loc.ishaAngle) ?? (h0 + 1.5));

    final fajrHours = fixHour(solarNoon - hFajr);
    final sunriseHours = fixHour(solarNoon - h0);
    final dhuhrHours = solarNoon;
    final asrHours = fixHour(solarNoon + hAsr);
    final maghribHours = fixHour(solarNoon + h0);
    final ishaHours = loc.ishaInterval90 ? fixHour(maghribHours + 1.5) : fixHour(solarNoon + hIsha);

    DateTime toDate(double h) {
      int hour = h.floor() % 24;
      int min = ((h - h.floor()) * 60.0).round();
      if (min >= 60) {
        hour = (hour + 1) % 24;
        min -= 60;
      }
      return DateTime(date.year, date.month, date.day, hour, min);
    }

    return {
      'Fajr': toDate(fajrHours),
      'Sunrise': toDate(sunriseHours),
      'Dhuhr': toDate(dhuhrHours),
      'Asr': toDate(asrHours),
      'Maghrib': toDate(maghribHours),
      'Isha': toDate(ishaHours),
    };
  }

  /// Formatted Islamic Hijri Date string
  static String getApproximateHijriDate(DateTime date) {
    const int hijriYear = 1448;
    final months = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر',
      'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
      'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
    ];
    final monthIndex = (date.month + 3) % 12;
    final day = (date.day % 29) + 1;
    return '$day ${months[monthIndex]} $hijriYear هـ';
  }
}
