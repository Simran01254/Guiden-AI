import 'package:get/get.dart';

import 'hand_pose_detector.dart';

class HandDetectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HandDetectionController>(() => HandDetectionController());
  }
}
