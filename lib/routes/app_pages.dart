import 'package:get/get.dart';
import 'package:guiden/modules/guider/camera/guided_camera_view_binding.dart';
import 'package:guiden/modules/light-frequency/light_frequency_binding.dart';
import 'package:guiden/modules/light-frequency/light_frequency_view.dart';

import '../modules/Splash/splash_view.dart';
import '../modules/guider/camera/guided_camera_view.dart';
import '../modules/guider/hand_detection_binding.dart';
import '../modules/guider/hand_detection_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/voice-assist/voice_assist_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;
  static const GUIDER = Routes.GUIDER;
  static const LIGHTFREQUENCY = Routes.LIGHTFREQUENCY;
  static const VOICE_ASSIST = Routes.VOICE_ASSIST;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.GUIDER,
      page: () => const HandDetectionView(),
      binding: HandDetectionBinding(),
    ),
    GetPage(
      name: _Paths.YOLO_DETECT,
      page: () => const GuidedCameraView(),
      binding: GuidedCameraViewBinding(),
    ),
    GetPage(
      name: _Paths.LIGHTFREQUENCY,
      page: () => const LightFrequencyView(),
      binding: LightFrequencyBinding(),
    ),
    GetPage(
      name: _Paths.VOICE_ASSIST,
      page: () => const VoiceAssistView(),
    ),
  ];
}
