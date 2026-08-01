import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../services/global_audio_controller.dart';
import '../../utils/audio_assets.dart';
import '../layout/layout_view.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animController;
  final AudioController audioController = Get.find<AudioController>();

  bool hasVibrated = false;
  bool hasSpoken = false;

  void initAnimation(Duration duration) {
    // 🔊 Play splash voice ONCE
    if (!hasSpoken) {
      hasSpoken = true;
      audioController.play(AudioAssets.splashWelcomeGuidenIsLoading);
    }

    animController = AnimationController(vsync: this, duration: duration);

    animController.addListener(() {
      final currentTimeMs = (animController.value * duration.inMilliseconds)
          .round();

      if (!hasVibrated && currentTimeMs >= 1720) {
        hasVibrated = true;
        HapticFeedback.heavyImpact();
      }
    });

    animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        gotoNext();
      }
    });

    animController.forward();
  }

  void gotoNext() {
    audioController.stop(); // optional, but clean
    Get.offAll(() => LayoutView());
  }

  @override
  void onClose() {
    animController.dispose();
    super.onClose();
  }
}
