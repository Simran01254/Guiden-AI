import 'package:get/get.dart';

import 'guider_camera_controller.dart';

class GuidedCameraViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MergedDetectionController>(() => MergedDetectionController());
  }
}
