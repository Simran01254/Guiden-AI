import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class AudioController extends GetxService {
  late final AudioPlayer _player;

  final RxBool isEnabled = true.obs;
  final RxBool isPlaying = false.obs;

  Future<AudioController> init() async {
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.stop);

    _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });

    return this;
  }

  /// Play a static voice asset
  Future<void> play(String assetPath, {bool interrupt = true}) async {
    if (!isEnabled.value) return;

    if (interrupt && isPlaying.value) {
      await _player.stop();
    }

    await _player.play(AssetSource(assetPath));
  }

  Future<void> stop() async {
    await _player.stop();
  }
}
