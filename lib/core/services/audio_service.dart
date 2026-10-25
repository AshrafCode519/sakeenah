import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class QuranAudioService {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;

  QuranAudioService._internal() {
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = (state == PlayerState.playing);
    });
  }

  late final AudioPlayer _player;
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<int?> currentAyahPlaying = ValueNotifier<int?>(null);

  String selectedReciter = 'ar.alafasy';

  static const Map<String, String> availableReciters = {
    'ar.alafasy': 'مشاري بن راشد العفاسي',
    'ar.abdulbasitmurattal': 'عبد الباسط عبد الصمد (مرتل)',
    'ar.husary': 'محمود خليل الحصري',
    'ar.minshawi': 'محمد صديق المنشاوي',
    'ar.saoodshuraym': 'سعود الشريم',
  };

  Future<void> playAyahAudio({required int globalAyahNumber, String? customUrl}) async {
    try {
      final url = customUrl ?? 'https://cdn.islamic.network/quran/audio/128/$selectedReciter/$globalAyahNumber.mp3';
      currentAyahPlaying.value = globalAyahNumber;
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('Audio playback error: $e');
      isPlaying.value = false;
      currentAyahPlaying.value = null;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
    currentAyahPlaying.value = null;
    isPlaying.value = false;
  }

  void dispose() {
    _player.dispose();
  }
}
