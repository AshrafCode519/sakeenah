class AyahModel {
  final int number; // Global Ayah index (1..6236)
  final int numberInSurah;
  final String text;
  final int surahNumber;
  final int juz;
  final int page;
  final String? audioUrl;
  final String? tafseer;

  const AyahModel({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.surahNumber,
    this.juz = 1,
    this.page = 1,
    this.audioUrl,
    this.tafseer,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json, {int? surahNumber}) {
    return AyahModel(
      number: json['number'] as int? ?? 1,
      numberInSurah: json['numberInSurah'] as int? ?? 1,
      text: json['text'] as String? ?? '',
      surahNumber: surahNumber ?? (json['surahNumber'] as int? ?? 1),
      juz: json['juz'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
      audioUrl: json['audio'] as String?,
      tafseer: json['tafseer'] as String?,
    );
  }

  AyahModel copyWith({
    int? number,
    int? numberInSurah,
    String? text,
    int? surahNumber,
    int? juz,
    int? page,
    String? audioUrl,
    String? tafseer,
  }) {
    return AyahModel(
      number: number ?? this.number,
      numberInSurah: numberInSurah ?? this.numberInSurah,
      text: text ?? this.text,
      surahNumber: surahNumber ?? this.surahNumber,
      juz: juz ?? this.juz,
      page: page ?? this.page,
      audioUrl: audioUrl ?? this.audioUrl,
      tafseer: tafseer ?? this.tafseer,
    );
  }
}
