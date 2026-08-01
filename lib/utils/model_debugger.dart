import 'package:tflite_flutter/tflite_flutter.dart';

class ModelDebugger {
  static Future<void> printModelDetails() async {
    final interpreter = await Interpreter.fromAsset(
      'hand_landmark_full.tflite',
    );

    print('╔══════════════════════════════════════════╗');
    print('║         MODEL DETAILS                     ║');
    print('╠══════════════════════════════════════════╣');

    final inputs = interpreter.getInputTensors();
    for (int i = 0; i < inputs.length; i++) {
      print('║ INPUT[$i]:');
      print('║   Shape: ${inputs[i].shape}');
      print('║   Type:  ${inputs[i].type}');
      print('║   Name:  ${inputs[i].name}');
    }

    print('╠══════════════════════════════════════════╣');

    final outputs = interpreter.getOutputTensors();
    for (int i = 0; i < outputs.length; i++) {
      print('║ OUTPUT[$i]:');
      print('║   Shape: ${outputs[i].shape}');
      print('║   Type:  ${outputs[i].type}');
      print('║   Name:  ${outputs[i].name}');
    }

    print('╚══════════════════════════════════════════╝');

    interpreter.close();
  }
}
