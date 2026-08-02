# Flutter Mobile Application Architecture

The **Guiden** mobile app is built using **Flutter**, **Dart (SDK ^3.10.0)**, and the **GetX** framework for state management, dependency injection, and clean routing.

---

## 1. Directory & Directory Layout

```
lib/
├── main.dart                       # App initialization & service registration
├── model/                          # Data models & configuration settings
│   └── detection_settings.dart     # Model threshold & camera parameters
├── modules/                        # Feature modules (UI Views & GetX Controllers)
│   ├── guider/                     # Main navigation & vision guidance feature
│   │   ├── camera/                 # Live camera feed controller & WebSocket client
│   │   ├── hand_detection_view.dart# MediaPipe 21-keypoint visualizer
│   │   └── yolo_detection_view.dart# Local object detection overlay
│   ├── light-frequency/            # Light & flicker frequency sensing feature
│   │   ├── light_frequency_view.dart
│   │   └── light_frequency_controller.dart
│   ├── voice-assist/               # Conversational audio interface feature
│   │   ├── voice_assist_view.dart
│   │   ├── voice_assist_controller.dart
│   │   └── pulsating_mic.dart
│   ├── onboarding/                 # User onboarding & intro flow
│   └── splash/                     # Splash screen & initial audio setup
├── routes/                         # App routing configurations
│   ├── app_pages.dart              # GetX Page definitions
│   └── app_routes.dart             # Named route constants
├── services/                       # Global services & hardware adapters
│   ├── hand_detector.dart          # MediaPipe Hand Landmarker integration
│   ├── yolo_model_manager.dart     # Ultralytics YOLO edge inference
│   ├── speech_service.dart         # Speech-to-text listener
│   ├── tts_service.dart            # Text-to-speech speaker
│   ├── voice_assistant_controller.dart
│   └── global_audio_controller.dart# Audio FX & haptics
└── utils/                          # Assets, colors, typography, & custom UI helpers
    ├── assets.dart                 # Image & vector asset references
    ├── audio_assets.dart           # Audio asset constants
    ├── colors.dart                 # High-contrast color palette
    ├── custom_tap.dart             # Accessibility tap & gesture handlers
    └── sf_font.dart                # San Francisco font styling
```

---

## 2. Core Modules Breakdown

### 2.1 Guider Module (`lib/modules/guider/`)
- **Camera View & Controller** ([`guided_camera_view.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/modules/guider/camera/guided_camera_view.dart), [`guider_camera_controller.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/modules/guider/camera/guider_camera_controller.dart)):
  - Manages hardware camera streams via `camera` package.
  - Controls low-latency WebSocket client connection streaming compressed JPEG frames to `guiden-server`.
  - Handles high refresh rate request via `flutter_refresh_rate_control`.
- **Hand Gesture Recognition** ([`hand_detection_view.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/modules/guider/hand_detection_view.dart)):
  - Integrates `hand_landmarker` plugin for MediaPipe tracking.
  - Draws 21 joint landmark nodes and skeleton connectors for touch-free physical targeting.

### 2.2 Light & Frequency Module (`lib/modules/light-frequency/`)
- **Light Frequency View & Controller** ([`light_frequency_view.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/modules/light-frequency/light_frequency_view.dart), [`light_frequency_controller.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/modules/light-frequency/light_frequency_controller.dart)):
  - Evaluates ambient light illuminance (Lux) and high-frequency flicker.
  - Provides pitch-modulated continuous audio tones allowing blind users to scan rooms for light sources, windows, or active lamps.

### 2.3 Voice Assist Module (`lib/modules/voice-assist/`)
- **Voice Assist View & Controller** ([`voice_assist_view.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/modules/voice-assist/voice_assist_view.dart), [`voice_assist_controller.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/modules/voice-assist/voice_assist_controller.dart)):
  - Conversational voice UI with animated mic pulsing ([`pulsating_mic.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/modules/voice-assist/pulsating_mic.dart)).
  - Listens for spoken queries, parses intents, and plays audio responses.

---

## 3. Global Service Architecture

GetX dependency injection registers singleton services upon application startup in [`lib/main.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/main.dart):

```dart
// Service Registration in main.dart
await Get.putAsync(() => AudioController().init());
Get.put(VoiceAssistantController(), permanent: true);
```

| Service Class | Responsibility |
| :--- | :--- |
| **`AudioController`** | Singleton managing background sound playback, haptic vibrations, and notification chimes. |
| **`VoiceAssistantController`** | Main speech orchestration service linking Speech-to-Text and TTS. |
| **`YoloModelManager`** | Singleton handling Ultralytics YOLO model lifecycle, bounding box calculation, and edge alerts. |
| **`HandDetector`** | Interface wrapper for MediaPipe hand tracking execution. |

---

## 4. UI Design System & Accessibility

1. **NeoPop Component Styling**: Implements Cyberpunk-inspired tactile NeoPop controls (`neopop` package) for maximum physical target readability.
2. **High-Contrast Palette**: Custom dark color palette ([`lib/utils/colors.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/utils/colors.dart)) optimized for low-vision users.
3. **Responsive Scaling**: Utilizes `flutter_screenutil` to dynamically scale UI elements, text, and hit targets across varying screen densities.
4. **San Francisco (SF) Typography**: Premium readable typography configuration ([`lib/utils/sf_font.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/utils/sf_font.dart)).
