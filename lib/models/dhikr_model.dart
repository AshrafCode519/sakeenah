class DhikrModel {
  final String id;
  final String category;
  final String categoryArabic;
  final String text;
  final int targetCount;
  int currentCount;
  final String benefit;
  final String source;

  DhikrModel({
    required this.id,
    required this.category,
    required this.categoryArabic,
    required this.text,
    required this.targetCount,
    this.currentCount = 0,
    this.benefit = '',
    this.source = '',
  });

  bool get isCompleted => currentCount >= targetCount;
  double get progress => targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  void increment() {
    if (currentCount < targetCount) {
      currentCount++;
    }
  }

  void reset() {
    currentCount = 0;
  }
}
