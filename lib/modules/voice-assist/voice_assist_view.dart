// lib/app/modules/voice_assist/view/voice_assist_view.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:guiden/modules/voice-assist/product_preview.dart';
import 'package:guiden/modules/voice-assist/pulsating_mic.dart';
import 'package:guiden/modules/voice-assist/response_card_widget.dart';
import 'package:guiden/modules/voice-assist/voice_assist_controller.dart';
import 'package:guiden/services/speech_service.dart';
import 'package:guiden/services/tts_service.dart';
import 'package:guiden/utils/colors.dart';

class VoiceAssistView extends GetView<VoiceAssistController> {
  const VoiceAssistView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SpeechService());
    Get.put(TtsService());
    Get.put(VoiceAssistController());
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: GestureDetector(
          onTap: controller.onScreenTap,
          behavior: HitTestBehavior.opaque,
          child: Obx(() => _buildBody(context)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // ─── Top Bar ────────────────────────────────────────────────
        _buildTopBar(),

        // ─── Main Content ───────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Camera preview OR captured image
                _buildVisualArea(),

                const SizedBox(height: 16),

                // Status message
                // _buildStatusSection(),
                const SizedBox(height: 12),

                // Loading indicator
                if (controller.isLoading.value) _buildLoadingSection(),

                // Response
                if (controller.responseText.value.isNotEmpty)
                  _buildResponseSection(),

                // User question display
                if (controller.userQuestion.value.isNotEmpty)
                  _buildUserQuestionCard(),

                // Partial speech feedback
                if (controller.partialSpeech.value.isNotEmpty &&
                    (controller.state.value ==
                            VoiceAssistState.listeningQuestion ||
                        controller.state.value == VoiceAssistState.listening))
                  _buildPartialSpeechCard(),

                const SizedBox(height: 100), // bottom padding for mic
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
            iconSize: 20,
            tooltip: 'Go back',
          ),
          const SizedBox(width: 8),
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Voice Assist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Obx(
                () => Text(
                  _stateLabel(controller.state.value),
                  style: TextStyle(
                    color: _stateColor(controller.state.value),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Restart button
          IconButton(
            onPressed: controller.restart,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            tooltip: 'Start over',
          ),
        ],
      ),
    );
  }

  // ─── Visual Area (Camera / Captured Image) ─────────────────────────────────

  Widget _buildVisualArea() {
    final state = controller.state.value;
    final showCamera =
        state == VoiceAssistState.waitingForCapture ||
        state == VoiceAssistState.listening ||
        state == VoiceAssistState.capturing ||
        state == VoiceAssistState.initializing;

    if (showCamera) {
      return _buildCameraPreview();
    }

    if (controller.hasCapture) {
      return ProductPreview(
        imageBytes: controller.capturedImageBytes!,
        productName: controller.productName.value.isNotEmpty
            ? controller.productName.value
            : null,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCameraPreview() {
    return Obx(() {
      if (!controller.isCameraReady.value ||
          controller.cameraController == null) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                ),
                SizedBox(height: 16),
                Text(
                  'Starting camera...',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 350.h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller.cameraController!),
                // Viewfinder overlay
                // _buildViewfinder(),
                // "Point camera at product" hint
                if (controller.state.value ==
                    VoiceAssistState.waitingForCapture)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Point at product • Say "Capture"',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
  // ─── Status Section ────────────────────────────────────────────────────────

  Widget _buildStatusSection() {
    final state = controller.state.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // State icon + message
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stateIcon(state),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  controller.statusMessage.value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          // Accessibility hint
          if (state == VoiceAssistState.waitingForCapture ||
              state == VoiceAssistState.listening)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tap anywhere on screen as alternative',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Loading Section ───────────────────────────────────────────────────────

  Widget _buildLoadingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Animated loader
          Text("Analyzing"),
          const SizedBox(height: 16),
          // Progress bar
          Obx(
            () => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: controller.loadingProgress.value,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            controller.state.value == VoiceAssistState.analyzingProduct
                ? 'Identifying product with AI...'
                : 'Processing your question...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Response Section ──────────────────────────────────────────────────────

  Widget _buildResponseSection() {
    return ResponseCard(
      text: controller.responseText.value,
      label: controller.state.value == VoiceAssistState.productIdentified
          ? 'Product Identified'
          : 'Answer',
      icon: controller.state.value == VoiceAssistState.productIdentified
          ? Icons.inventory_2_outlined
          : Icons.question_answer_outlined,
      accentColor: controller.state.value == VoiceAssistState.productIdentified
          ? Colors.greenAccent
          : Colors.blueAccent,
      processingTimeMs: controller.processingTimeMs.value > 0
          ? controller.processingTimeMs.value
          : null,
    );
  }

  Widget _buildUserQuestionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              controller.userQuestion.value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialSpeechCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              controller.partialSpeech.value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Controls ───────────────────────────────────────────────────────

  Widget _buildBottomControls() {
    final state = controller.state.value;
    final isListening =
        state == VoiceAssistState.listening ||
        state == VoiceAssistState.listeningQuestion;

    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F0F1A).withOpacity(0.0),
            const Color(0xFF0F0F1A),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsatingMic(
            isActive: isListening,
            color: isListening ? Colors.redAccent : Colors.blueAccent,
            size: 64,
            onTap: controller.onScreenTap,
          ),
          const SizedBox(height: 8),
          Text(
            isListening
                ? 'Listening...'
                : state == VoiceAssistState.playingResponse
                ? '🔊 Speaking...'
                : 'Tap to capture',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _stateLabel(VoiceAssistState s) {
    switch (s) {
      case VoiceAssistState.initializing:
        return 'Starting up...';
      case VoiceAssistState.waitingForCapture:
        return 'Ready to scan';
      case VoiceAssistState.listening:
        return 'Listening';
      case VoiceAssistState.capturing:
        return 'Capturing';
      case VoiceAssistState.analyzingProduct:
        return 'Analyzing';
      case VoiceAssistState.productIdentified:
        return 'Product found';
      case VoiceAssistState.waitingForQuestion:
        return 'Ask a question';
      case VoiceAssistState.listeningQuestion:
        return 'Listening';
      case VoiceAssistState.processingQuestion:
        return 'Processing';
      case VoiceAssistState.playingResponse:
        return 'Speaking';
      case VoiceAssistState.complete:
        return 'Ready';
      case VoiceAssistState.error:
        return 'Error';
    }
  }

  Color _stateColor(VoiceAssistState s) {
    switch (s) {
      case VoiceAssistState.listening:
      case VoiceAssistState.listeningQuestion:
        return Colors.redAccent;
      case VoiceAssistState.analyzingProduct:
      case VoiceAssistState.processingQuestion:
        return Colors.orangeAccent;
      case VoiceAssistState.productIdentified:
      case VoiceAssistState.complete:
        return Colors.greenAccent;
      case VoiceAssistState.playingResponse:
        return Colors.blueAccent;
      case VoiceAssistState.error:
        return Colors.red;
      default:
        return Colors.white54;
    }
  }

  Widget _stateIcon(VoiceAssistState s) {
    switch (s) {
      case VoiceAssistState.initializing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
        );
      case VoiceAssistState.listening:
      case VoiceAssistState.listeningQuestion:
        return const Icon(Icons.hearing, color: Colors.redAccent, size: 22);
      case VoiceAssistState.capturing:
        return const Icon(Icons.camera, color: Colors.blueAccent, size: 22);
      case VoiceAssistState.analyzingProduct:
      case VoiceAssistState.processingQuestion:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orangeAccent,
          ),
        );
      case VoiceAssistState.productIdentified:
        return const Icon(
          Icons.check_circle,
          color: Colors.greenAccent,
          size: 22,
        );
      case VoiceAssistState.playingResponse:
        return const Icon(Icons.volume_up, color: Colors.blueAccent, size: 22);
      case VoiceAssistState.error:
        return const Icon(Icons.error_outline, color: Colors.red, size: 22);
      default:
        return const Icon(Icons.info_outline, color: Colors.white54, size: 22);
    }
  }
}
