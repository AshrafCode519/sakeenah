class LocationModel {
  final String country;
  final String city;
  final String? governorate;
  final double latitude;
  final double longitude;
  final double utcOffset;
  final String methodName;
  final int methodId;
  final double fajrAngle;
  final double ishaAngle;
  final bool ishaInterval90;

  const LocationModel({
    required this.country,
    required this.city,
    this.governorate,
    required this.latitude,
    required this.longitude,
    required this.utcOffset,
    required this.methodName,
    this.methodId = 5,
    this.fajrAngle = 18.0,
    this.ishaAngle = 17.5,
    this.ishaInterval90 = false,
  });

  String get governorateName => governorate ?? city;

  /// Full display name e.g. "محافظة الدقهلية (المنصورة) - مصر" or "محافظة القاهرة - مصر"
  String get displayName {
    if (governorate != null && governorate != city) {
      return '$governorate ($city)، $country';
    }
    return '${governorate ?? city}، $country';
  }

  /// Short display name for headers and pills e.g. "محافظة الدقهلية (المنصورة)" or "محافظة القاهرة"
  String get shortDisplayName {
    if (governorate != null && governorate != city) {
      return '$governorate ($city)';
    }
    return governorate ?? city;
  }
}

