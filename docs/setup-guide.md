# Setup and Installation Guide

This guide provides step-by-step instructions to set up, configure, and run both the **Guiden Mobile Application** and the **Guiden Python AI Server**.

---

## 1. Environment & System Requirements

### Prerequisites

| Component | Required Version / Details |
| :--- | :--- |
| **Flutter SDK** | `^3.10.0` or higher |
| **Dart SDK** | `^3.10.0` |
| **Python** | `3.10` or `3.11` |
| **Operating System** | macOS, Linux, or Windows 10/11 |
| **Mobile Platforms** | Android (API level 24+) or iOS (iOS 14.0+) with Camera access |
| **Hardware** | Camera-enabled target device or emulator with webcam forwarding |

---

## 2. Python Backend Server Setup (`guiden-server`)

The backend server relies on **FastAPI**, **Uvicorn**, **Google Gemini 2.0 Flash API**, and **ElevenLabs API** for streaming audio synthesis.

### Step 1: Navigate to Server Directory
```bash
cd guiden-server
```

### Step 2: Create and Activate Virtual Environment
On Linux / macOS:
```bash
python3 -m venv .venv
source .venv/bin/activate
```
On Windows (PowerShell):
```powershell
python -m venv .venv
\.venv\Scripts\Activate.ps1
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

*Note: Required python packages include `fastapi`, `uvicorn`, `websockets`, `google-genai`, `elevenlabs`, `opencv-python`, `pillow`, `torch`.*

### Step 4: Environment Variables Configuration
Set your API keys as environment variables:

On Linux / macOS:
```bash
export GEMINI_API_KEY="your_google_gemini_api_key"
export ELEVENLABS_API_KEY="your_elevenlabs_api_key"
```

On Windows (PowerShell):
```powershell
$env:GEMINI_API_KEY="your_google_gemini_api_key"
$env:ELEVENLABS_API_KEY="your_elevenlabs_api_key"
```

### Step 5: Launch the Server
Run the Uvicorn server on port `8765`:
```bash
uvicorn assist_server:app --host 0.0.0.0 --port 8765 --reload
```

The WebSocket server will be accessible at `ws://localhost:8765/ws/stream` (or your local network IP for physical device testing, e.g., `ws://192.168.1.X:8765/ws/stream`).

---

## 3. Flutter Mobile Client Setup (`guiden`)

### Step 1: Verify Flutter Installation
Ensure Flutter SDK is properly configured:
```bash
flutter doctor
```

### Step 2: Install Flutter Dependencies
From the project root directory:
```bash
flutter pub get
```

### Step 3: Verify Assets & Neural Models
Ensure the following directories contain model weights and assets as defined in [`pubspec.yaml`](file:///c:/Users/ankus/Downloads/guiden/pubspec.yaml):
- `assets/images/` - Brand icons and UI graphics.
- `assets/lottie/` - Lottie animation files.
- `assets/fonts/sf/` - San Francisco typography.
- `assets/models/` - TFLite & YOLO models for edge detection.
- `assets/audio/` - Haptic feedback sound clips.

### Step 4: Configure Target Host IP
If testing on a physical device over Wi-Fi, update the WebSocket server URL in [`lib/modules/guider/camera/guider_camera_controller.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/modules/guider/camera/guider_camera_controller.dart) to point to your computer's local IP address:
```dart
// Example: ws://192.168.1.50:8765/ws/stream
final String serverUrl = 'ws://YOUR_LOCAL_IP:8765/ws/stream';
```

### Step 5: Launch the Application

#### Run on Connected Physical Android Device:
```bash
flutter run -d android
```

#### Run on Connected iOS Device:
```bash
flutter run -d ios
```

---

## 4. Platform-Specific Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
Ensure the following permissions are present:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MICROPHONE" />
```

### iOS (`ios/Runner/Info.plist`)
Ensure the following usage descriptions are added:
```xml
<key>NSCameraUsageDescription</key>
<string>Guiden needs camera access for continuous real-time navigation guidance.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Guiden requires microphone access for voice assistant commands.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Guiden uses speech recognition for hands-free interaction.</string>
```

---

## 5. Troubleshooting Common Setup Issues

| Issue | Solution |
| :--- | :--- |
| **WebSocket Connection Failed** | Verify host computer and phone are on the same Wi-Fi network and firewall allows port `8765`. |
| **TFLite / YOLO Model Load Error** | Confirm model files exist under `assets/models/` and are listed under assets in [`pubspec.yaml`](file:///c:/Users/ankus/Downloads/guiden/pubspec.yaml). |
| **ElevenLabs Audio Error** | Verify `ELEVENLABS_API_KEY` is exported correctly and active. |
| **Camera Black Screen** | Ensure camera permissions are granted in system settings on target device. |
