import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:guiden/modules/splash/splash_controller.dart';
import 'package:lottie/lottie.dart';

import '../../utils/assets.dart';
import '../../utils/colors.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final SplashController controller = Get.put(SplashController());

    bool hasVibrated = false;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Center(
        child: Lottie.asset(
          AppAssets.splashLottieBlack,
          width: 1.sw,
          height: 1.sh,
          frameRate: FrameRate.max,

          onLoaded: (composition) {
            controller.initAnimation(composition.duration);
          },
        ),
      ),
    );
  }
}
