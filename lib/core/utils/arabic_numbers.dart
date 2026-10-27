class ArabicUtils {
  static const List<String> _arabicDigits = [
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'
  ];

  /// Converts standard digits to Eastern Arabic numerals (١، ٢، ٣...)
  
  /// Converts Eastern Arabic numerals (١، ٢، ٣...) to standard integer
  static int fromArabicDigits(String input) {
    const map = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      buffer.write(map[ch] ?? ch);
    }
    return int.tryParse(buffer.toString()) ?? 1;
  }

  static String toArabicDigits(dynamic number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      final digit = int.tryParse(char);
      if (digit != null) {
        buffer.write(_arabicDigits[digit]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Formats Ayah number inside decorative Islamic brackets ﴿ ١ ﴾
  static String formatAyahNumber(int number) {
    return '﴿${toArabicDigits(number)}﴾';
  }

  static const List<String> _juzNames = [
    'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
    'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر', 'السادس عشر', 'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون',
    'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون', 'الرابع والعشرون', 'الخامس والعشرون', 'السادس والعشرون', 'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون',
  ];

  /// Returns Arabic Juz Title e.g. "الجُزْءُ الأَوَّل"
  static String getJuzName(int juz) {
    if (juz >= 1 && juz <= _juzNames.length) {
      return 'الجُزْءُ ${_juzNames[juz - 1]}';
    }
    return 'الجُزْءُ ${toArabicDigits(juz)}';
  }
}
