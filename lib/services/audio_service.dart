import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// أصواتُ اللعبة، معرَّفةً بأسمائها لا بمساراتها.
enum GameSound {
  correct('correct.wav'),
  wrong('wrong.wav'),
  torch('torch.wav'),
  levelUp('levelup.wav'),
  stage('stage.wav'),
  ambience('ambience.wav');

  const GameSound(this.fileName);

  final String fileName;
}

/// واجهةُ الصوت. مجرَّدةٌ عن مُشغِّلٍ بعينه، فيمكن استبدالُ المحرّك
/// أو إسكاتُ اللعبة كلِّها من موضعٍ واحد.
abstract class AudioService {
  Future<void> preload();

  void play(GameSound sound);

  /// كتمُ الصوت وإعادتُه — إعدادٌ يملكه اللاعب لا اللعبة.
  set muted(bool value);

  bool get muted;
}

/// تنفيذٌ فوق `flame_audio`.
///
/// لا موسيقى خلفيّة في اللعبة عن قصد؛ أصواتٌ قصيرةٌ عند الحدث فقط،
/// فالقراءةُ تحتاج هدوءًا، والضجيجُ يُنسي الجملةَ التي على اللوحة.
class FlameAudioService implements AudioService {
  FlameAudioService();

  bool _muted = false;
  bool _ready = false;

  @override
  bool get muted => _muted;

  @override
  set muted(bool value) => _muted = value;

  @override
  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll(
        GameSound.values.map((s) => s.fileName).toList(growable: false),
      );
      _ready = true;
    } on Object catch (error) {
      // غيابُ الصوت لا يُعطّل اللعب؛ نمضي صامتين.
      debugPrint('تعذّر تحميلُ الأصوات: $error');
      _ready = false;
    }
  }

  @override
  void play(GameSound sound) {
    if (_muted || !_ready) return;
    try {
      FlameAudio.play(sound.fileName, volume: 0.55);
    } on Object catch (error) {
      debugPrint('تعذّر تشغيلُ الصوت ${sound.fileName}: $error');
    }
  }
}

/// تنفيذٌ صامتٌ للاختبارات ولبيئاتٍ لا صوتَ فيها.
class SilentAudioService implements AudioService {
  @override
  bool muted = true;

  @override
  void play(GameSound sound) {}

  @override
  Future<void> preload() async {}
}
