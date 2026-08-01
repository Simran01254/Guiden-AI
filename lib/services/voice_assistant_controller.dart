// lib/services/voice_assistant_controller.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../routes/app_pages.dart';

class VoiceAssistantController extends GetxController {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  final RxBool isListening = false.obs;
  final RxBool isAvailable = false.obs;
  final RxString lastWords = ''.obs;
  final RxBool isSpeaking = false.obs;
  final RxBool isInitialized = false.obs;
  final RxBool isPaused = false.obs;

  @override
  void onInit() {
    super.onInit();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeTts();
  }

  Future<void> startVoiceAssistant() async {
    if (isInitialized.value) return;

    await Future.delayed(const Duration(milliseconds: 500));
    await _initializeSpeech();
    isInitialized.value = true;
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      isSpeaking.value = true;
    });

    _flutterTts.setCompletionHandler(() {
      isSpeaking.value = false;
      // Resume listening after speaking (only if not paused)
      if (isAvailable.value &&
          !isListening.value &&
          isInitialized.value &&
          !isPaused.value) {
        Future.delayed(const Duration(milliseconds: 300), () {
          startListening();
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      isSpeaking.value = false;
      print("TTS Error: $msg");
    });
  }

  Future<void> _initializeSpeech() async {
    try {
      var status = await Permission.microphone.request();
      if (!status.isGranted) {
        print("Microphone permission denied");
        await speak("Microphone permission is required for voice navigation");
        return;
      }

      isAvailable.value = await _speech.initialize(
        onStatus: (status) {
          print('Speech Status: $status');
          if (status == 'done' || status == 'notListening') {
            isListening.value = false;
            // Restart listening after a brief pause (only if not paused)
            if (isAvailable.value &&
                !isSpeaking.value &&
                isInitialized.value &&
                !isPaused.value) {
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (isAvailable.value &&
                    !isSpeaking.value &&
                    !isListening.value &&
                    !isPaused.value) {
                  startListening();
                }
              });
            }
          }
        },
        onError: (error) {
          print('Speech Error: $error');
          isListening.value = false;

          if (isPaused.value) return;

          if (error.permanent == false) {
            Future.delayed(const Duration(seconds: 3), () {
              if (isAvailable.value &&
                  !isSpeaking.value &&
                  !isListening.value &&
                  isInitialized.value &&
                  !isPaused.value) {
                startListening();
              }
            });
          } else {
            Future.delayed(const Duration(seconds: 5), () {
              if (isAvailable.value &&
                  !isSpeaking.value &&
                  !isListening.value &&
                  isInitialized.value &&
                  !isPaused.value) {
                startListening();
              }
            });
          }
        },
      );

      if (isAvailable.value) {
        await speak(
          "Voice assistant activated. Say navigate to switch screens.",
        );
      } else {
        print("Voice assistant is not available on this device");
        await speak("Voice assistant is not available on this device");
      }
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      isAvailable.value = false;
    }
  }

  void startListening() {
    if (!isAvailable.value ||
        isListening.value ||
        isSpeaking.value ||
        !isInitialized.value ||
        isPaused.value) {
      return;
    }

    try {
      _speech.listen(
        onResult: (result) {
          lastWords.value = result.recognizedWords.toLowerCase();
          if (result.finalResult) {
            print('Final result: ${lastWords.value}');
            _processCommand(lastWords.value);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.confirmation,
      );
      isListening.value = true;
    } catch (e) {
      print('Error starting listening: $e');
      isListening.value = false;
    }
  }

  void stopListening() {
    if (isListening.value) {
      _speech.stop();
      isListening.value = false;
    }
  }

  Future<void> speak(String text) async {
    if (isSpeaking.value) {
      await _flutterTts.stop();
    }
    stopListening();
    await _flutterTts.speak(text);
  }

  void _processCommand(String command) {
    final currentRoute = Get.currentRoute;
    print('Processing command: $command');

    // Navigate command
    if (command.contains('navigate')) {
      if (command.contains('gesture') || command.contains('hand')) {
        if (currentRoute != '/hand-detection') {
          Get.toNamed('/hand-detection');
          speak("Navigating to Gesture Test");
        } else {
          speak("You are already on Gesture Test screen");
        }
      } else if (command.contains('assist') ||
          command.contains('camera') ||
          command.contains('detect')) {
        if (currentRoute != '/yolo-detect') {
          Get.toNamed('/yolo-detect');
          speak("Navigating to Path Assistance");
        } else {
          speak("You are already on YOLO detection screen");
        }
      } else if (command.contains('light') || command.contains('frequency')) {
        if (currentRoute != '/light-frequency') {
          Get.toNamed('/light-frequency');
          speak("Navigating to Light Frequency. Enabling frequency detector.");
        } else {
          speak("You are already on Light Frequency screen");
        }
      } else if (command.contains('voice') ||
          command.contains('product') ||
          command.contains('assist')) {
        if (currentRoute != Routes.VOICE_ASSIST) {
          Get.toNamed(Routes.VOICE_ASSIST);
          speak("Navigating to Voice Assist");
        } else {
          speak("You are already on Voice Assist screen");
        }
      } else if (command.contains('home') || command.contains('main')) {
        if (currentRoute != '/') {
          Get.offAllNamed('/');
          speak("Navigating to home screen");
        } else {
          speak("You are already on home screen");
        }
      } else {
        speak(
          "Please specify where to navigate. Say gesture, YOLO, light frequency, or voice assist",
        );
      }
    }
    // Back command
    else if (command.contains('back') || command.contains('return')) {
      if (Get.currentRoute != '/') {
        Get.back();
        speak("Going back");
      } else {
        speak("You are on the home screen");
      }
    }
    // Help command
    else if (command.contains('help')) {
      speak(
        "Say navigate gesture for gesture test, navigate YOLO for detection, navigate light for light frequency, navigate voice assist for product information, or say back to go back",
      );
    }
    // Where am I command
    else if (command.contains('where') || command.contains('current')) {
      String screenName = _getScreenName(currentRoute);
      speak("You are currently on $screenName");
    }
  }

  String _getScreenName(String route) {
    if (route == Routes.VOICE_ASSIST) {
      return 'Voice Assist screen';
    }
    switch (route) {
      case '/hand-detection':
        return 'Gesture Test screen';
      case '/yolo-detect':
        return 'YOLO detection screen';
      case '/light-frequency':
        return 'Light Frequency screen';
      case '/':
      case '/LayoutView':
        return 'Home screen';
      default:
        return 'unknown screen';
    }
  }

  void pauseVoiceAssistant() {
    isPaused.value = true;
    stopListening();
    print("Voice assistant paused");
  }

  void resumeVoiceAssistant() {
    isPaused.value = false;
    print("Voice assistant resuming");
    if (isInitialized.value && !isSpeaking.value) {
      Future.delayed(const Duration(milliseconds: 500), () {
        startListening();
      });
    }
  }

  @override
  void onClose() {
    stopListening();
    _speech.cancel();
    _flutterTts.stop();
    super.onClose();
  }
}
