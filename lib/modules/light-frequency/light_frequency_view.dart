import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'light_frequency_controller.dart';

class LightFrequencyView extends GetView<LightFrequencyController> {
  const LightFrequencyView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LightFrequencyController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Obx(() {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              Text(
                controller.isRunning.value
                    ? "Light Detection Active"
                    : "Tap to Start",
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  if (controller.isRunning.value) {
                    controller.stop();
                  } else {
                    controller.start();
                  }
                },
                child: Text(controller.isRunning.value ? "Stop" : "Start"),
              ),
            ],
          );
        }),
      ),
    );
  }
}
