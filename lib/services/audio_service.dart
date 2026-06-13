import 'package:audioplayers/audioplayers.dart';
import '../data/prefs.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final _pop = AudioPlayer();
  final _chime = AudioPlayer();

  Future<void> playPop() async {
    if (!await Prefs.soundEnabled()) return;
    await _pop.stop();
    await _pop.play(AssetSource('sounds/pop.wav'));
  }

  Future<void> playChime() async {
    if (!await Prefs.soundEnabled()) return;
    await _chime.stop();
    await _chime.play(AssetSource('sounds/chime.wav'));
  }

  Future<void> dispose() async {
    await _pop.dispose();
    await _chime.dispose();
  }
}
