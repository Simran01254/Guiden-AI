# Development & Contribution Workflow

This guide details code standards, architectural patterns, and procedures for developers extending **Guiden**.

---

## 1. Code Standards & Best Practices

### Flutter / Dart Standards

- Follow the official [Effective Dart](https://dart.dev/guides/language/effective-dart) rules enforced by `flutter_lints` ([`analysis_options.yaml`](file:///c:/Users/ankus/Downloads/guiden/analysis_options.yaml)).
- **GetX Pattern**: Place business logic inside `GetxController` classes under `lib/modules/<feature>/`. Do not perform heavy computations or state mutations directly inside UI `Widget.build()` methods.
- **Service Isolation**: Global platform channels (TTS, Speech-to-Text, Camera, Sensors) belong in singleton classes under `lib/services/` registered via `Get.put()` or `Get.putAsync()`.

### Python Backend Standards

- Follow **PEP 8** style guidelines for all Python code in `guiden-server/`.
- Maintain asynchronous I/O (`async`/`await`) across FastAPI WebSocket endpoints to prevent blocking main event loops during Gemini API calls.

---

## 2. Adding a New Flutter Feature Module

To add a new feature (e.g., `obstacle-map`):

### Step 1: Create Module Hierarchy under `lib/modules/`
```
lib/modules/obstacle-map/
├── obstacle_map_binding.dart
├── obstacle_map_controller.dart
└── obstacle_map_view.dart
```

### Step 2: Define Binding & Controller
```dart
// obstacle_map_binding.dart
import 'package:get/get.dart';
import 'obstacle_map_controller.dart';

class ObstacleMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ObstacleMapController>(() => ObstacleMapController());
  }
}
```

### Step 3: Register Route in `lib/routes/`
Add route constants to [`lib/routes/app_routes.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/routes/app_routes.dart) and register the `GetPage` in [`lib/routes/app_pages.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/routes/app_pages.dart):
```dart
GetPage(
  name: _Paths.OBSTACLE_MAP,
  page: () => const ObstacleMapView(),
  binding: ObstacleMapBinding(),
),
```

---

## 3. Extending the Python AI Server (`guiden-server`)

### Adding Custom WebSocket Event Types

To support a new event type (e.g., `"depth_map"`) in [`guiden-server/assist_server.py`](file:///c:/Users/ankus/Downloads/guiden/guiden-server/assist_server.py):

```python
@app.websocket("/ws/stream")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")
            
            if msg_type == "frame":
                await process_navigation_frame(websocket, data)
            elif msg_type == "depth_map":
                await process_depth_map(websocket, data)
    except WebSocketDisconnect:
        print("Client disconnected")
```

---

## 4. Deploying Custom TFLite / YOLO Models

1. Convert model to TensorFlow Lite (`.tflite`) format.
2. Place model weights inside [`assets/models/`](file:///c:/Users/ankus/Downloads/guiden/assets/models/).
3. Register the asset path in [`pubspec.yaml`](file:///c:/Users/ankus/Downloads/guiden/pubspec.yaml):
   ```yaml
   flutter:
     assets:
       - assets/models/custom_yolo.tflite
   ```
4. Load the model via [`lib/services/yolo_model_manager.dart`](file:///c:/Users/ankus/Downloads/guiden/lib/services/yolo_model_manager.dart).

---

## 5. Testing & Verification

### Run Flutter Unit & Widget Tests
```bash
flutter test
```

### Analyze Dart Static Code
```bash
flutter analyze
```

### Test Python Server Endpoint
Run server locally and execute WebSocket connection test:
```bash
uvicorn assist_server:app --port 8765
```
