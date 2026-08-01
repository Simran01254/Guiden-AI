import 'package:get/get.dart';
import 'package:guiden/modules/light-frequency/light_frequency_controller.dart';

class LightFrequencyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LightFrequencyController>(() => LightFrequencyController());
  }
}
