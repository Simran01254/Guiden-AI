import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:guiden/modules/layout/blob_button.dart';
import 'package:guiden/services/voice_assistant_controller.dart';
import 'package:guiden/utils/assets.dart';
import 'package:guiden/utils/colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../utils/sf_font.dart';

class LayoutView extends StatefulWidget {
  const LayoutView({super.key});

  @override
  State<LayoutView> createState() => _LayoutViewState();
}

class _LayoutViewState extends State<LayoutView> {
  final voiceAssistant = Get.find<VoiceAssistantController>();
  bool _hasStartedVoice = false;

  @override
  void initState() {
    super.initState();

    // Start voice assistant after this screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_hasStartedVoice) {
        _hasStartedVoice = true;
        // Start voice assistant after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        await voiceAssistant.startVoiceAssistant();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      bottomNavigationBar: Container(
        height: 60.h,
        // color: Color(0xFF1A1A1A),
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage("assets/images/bg-2.png"),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Powered by caffeine, built at",
              style: SFPro.font(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            6.horizontalSpace,
            Image.asset("assets/images/quack.png", width: 65.w),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.appBarBg,
            expandedHeight: 80,
            collapsedHeight: 80,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: -110,
                  child: SvgPicture.asset(
                    AppAssets.onlyLogoWhite,
                    width: 0.4.sw,
                  ),
                ),
                Positioned(
                  left: 70,
                  child: SvgPicture.asset(
                    AppAssets.onlyTextWhite,
                    width: 0.25.sw,
                  ),
                ),
                // Voice status indicator
                Positioned(
                  right: 16,
                  child: Obx(
                    () => Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: voiceAssistant.isListening.value
                            ? Colors.green.withOpacity(0.3)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        voiceAssistant.isListening.value
                            ? Icons.mic
                            : Icons.mic_off,
                        color: voiceAssistant.isListening.value
                            ? Colors.green
                            : Colors.white.withOpacity(0.7),
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverFillRemaining(
            child: Container(
              // decoration: BoxDecoration(
              //   image: DecorationImage(
              //     fit: BoxFit.cover,
              //     image: AssetImage("assets/images/bg-2.png"),
              //   ),
              // ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ───── Row 1 (2 buttons) ─────
                    Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          child: NeoButton(
                            title: "Gesture Pose",
                            icon: Iconsax.finger_cricle,
                            onTap: () {
                              voiceAssistant.speak("Opening Gesture Test");
                              Get.toNamed('/hand-detection');
                            },
                          ),
                        ),
                        Expanded(
                          child: NeoButton(
                            title: "Navigation Assist",
                            icon: Iconsax.camera_copy,
                            onTap: () {
                              voiceAssistant.speak("Opening Navigation Assist");
                              Get.toNamed('/yolo-detect');
                            },
                          ),
                        ),
                      ],
                    ),

                    2.verticalSpace,

                    // ───── Row 2 (1 full-width button) ─────
                    Column(
                      spacing: 5,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: NeoButton(
                                title: "Light Frequency",
                                icon: Iconsax.cloud_lightning,
                                onTap: () {
                                  voiceAssistant.speak(
                                    "Opening Light Frequency",
                                  );
                                  Get.toNamed('/light-frequency');
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: NeoButton(
                                title: "Identify Currency",
                                icon: Iconsax.cloud_lightning,
                                onTap: () {
                                  voiceAssistant.speak(
                                    "Opening Light Frequency",
                                  );
                                  Get.toNamed('/light-frequency');
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: NeoButton(
                                title: "Voice Assist",
                                icon: Iconsax.cloud_lightning,
                                onTap: () {
                                  voiceAssistant.speak("Opening Voice Assist");
                                  Get.toNamed('/voice-assist');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridItem({required IconData icon, required String title}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60.sp, color: Colors.white),
          8.verticalSpace,
          Text(
            title,
            style: SFPro.font(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
