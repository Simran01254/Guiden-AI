import 'package:get/get.dart';
import 'yolo_detection_controller.dart';

class YoloDetectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<YoloDetectionController>(() => YoloDetectionController());
  }
}
