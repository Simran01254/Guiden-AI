import 'dart:math' as math;

import 'package:hand_landmarker/hand_landmarker.dart';

enum HandGesture { peace, openHand, fist, unknown }

class GestureDetector {
  /// MediaPipe Hand Landmark indices
  static const int wrist = 0;
  static const int thumbTip = 4;
  static const int indexMcp = 5;
  static const int indexPip = 6;
  static const int indexDip = 7;
  static const int indexTip = 8;
  static const int middleMcp = 9;
  static const int middlePip = 10;
  static const int middleDip = 11;
  static const int middleTip = 12;
  static const int ringMcp = 13;
  static const int ringPip = 14;
  static const int ringDip = 15;
  static const int ringTip = 16;
  static const int pinkyMcp = 17;
  static const int pinkyPip = 18;
  static const int pinkyDip = 19;
  static const int pinkyTip = 20;

  /// Detect gesture from hand landmarks
  static HandGesture detectGesture(Hand hand) {
    final landmarks = hand.landmarks;

    if (landmarks.length < 21) return HandGesture.unknown;

    if (_isPeace(landmarks)) return HandGesture.peace;
    if (_isOpenHand(landmarks)) return HandGesture.openHand;
    if (_isFist(landmarks)) return HandGesture.fist;

    return HandGesture.unknown;
  }

  /// Check if a finger is extended
  static bool _isFingerExtended(
    List<Landmark> landmarks,
    int mcp,
    int pip,
    int dip,
    int tip,
  ) {
    final tipPos = landmarks[tip];
    final pipPos = landmarks[pip];
    final wristPos = landmarks[wrist];

    final tipToWrist = _distance(tipPos, wristPos);
    final pipToWrist = _distance(pipPos, wristPos);

    if (tipToWrist <= pipToWrist) return false;

    final angle = _calculateAngle(
      landmarks[mcp],
      landmarks[pip],
      landmarks[tip],
    );

    return angle > 150;
  }

  /// Check if thumb is extended
  static bool _isThumbExtended(List<Landmark> landmarks) {
    final thumbTipPos = landmarks[thumbTip];
    final indexMcpPos = landmarks[indexMcp];
    final wristPos = landmarks[wrist];

    final thumbToIndex = _distance(thumbTipPos, indexMcpPos);
    final wristToIndex = _distance(wristPos, indexMcpPos);

    return thumbToIndex > wristToIndex * 0.8;
  }

  /// Check if finger is curled
  static bool _isFingerCurled(
    List<Landmark> landmarks,
    int mcp,
    int pip,
    int dip,
    int tip,
  ) {
    final tipPos = landmarks[tip];
    final mcpPos = landmarks[mcp];
    final wristPos = landmarks[wrist];

    final tipToWrist = _distance(tipPos, wristPos);
    final mcpToWrist = _distance(mcpPos, wristPos);

    final pipPos = landmarks[pip];
    final tipToMcp = _distance(tipPos, mcpPos);
    final pipToMcp = _distance(pipPos, mcpPos);

    return tipToMcp < pipToMcp * 1.5 || tipToWrist < mcpToWrist * 1.1;
  }

  /// Detect Peace sign (index and middle fingers extended, others curled)
  static bool _isPeace(List<Landmark> landmarks) {
    final indexExtended = _isFingerExtended(
      landmarks,
      indexMcp,
      indexPip,
      indexDip,
      indexTip,
    );
    final middleExtended = _isFingerExtended(
      landmarks,
      middleMcp,
      middlePip,
      middleDip,
      middleTip,
    );
    final ringCurled = _isFingerCurled(
      landmarks,
      ringMcp,
      ringPip,
      ringDip,
      ringTip,
    );
    final pinkyCurled = _isFingerCurled(
      landmarks,
      pinkyMcp,
      pinkyPip,
      pinkyDip,
      pinkyTip,
    );

    // Check finger spread
    final indexTipPos = landmarks[indexTip];
    final middleTipPos = landmarks[middleTip];
    final fingerSpread = _distance(indexTipPos, middleTipPos);

    final indexMcpPos = landmarks[indexMcp];
    final middleMcpPos = landmarks[middleMcp];
    final mcpDistance = _distance(indexMcpPos, middleMcpPos);

    final isSpreading = fingerSpread > mcpDistance * 0.8;

    return indexExtended &&
        middleExtended &&
        ringCurled &&
        pinkyCurled &&
        isSpreading;
  }

  /// Detect open hand (all fingers extended)
  static bool _isOpenHand(List<Landmark> landmarks) {
    final indexExtended = _isFingerExtended(
      landmarks,
      indexMcp,
      indexPip,
      indexDip,
      indexTip,
    );
    final middleExtended = _isFingerExtended(
      landmarks,
      middleMcp,
      middlePip,
      middleDip,
      middleTip,
    );
    final ringExtended = _isFingerExtended(
      landmarks,
      ringMcp,
      ringPip,
      ringDip,
      ringTip,
    );
    final pinkyExtended = _isFingerExtended(
      landmarks,
      pinkyMcp,
      pinkyPip,
      pinkyDip,
      pinkyTip,
    );
    final thumbExtended = _isThumbExtended(landmarks);

    return indexExtended &&
        middleExtended &&
        ringExtended &&
        pinkyExtended &&
        thumbExtended;
  }

  /// Detect fist (all fingers curled)
  static bool _isFist(List<Landmark> landmarks) {
    final indexCurled = _isFingerCurled(
      landmarks,
      indexMcp,
      indexPip,
      indexDip,
      indexTip,
    );
    final middleCurled = _isFingerCurled(
      landmarks,
      middleMcp,
      middlePip,
      middleDip,
      middleTip,
    );
    final ringCurled = _isFingerCurled(
      landmarks,
      ringMcp,
      ringPip,
      ringDip,
      ringTip,
    );
    final pinkyCurled = _isFingerCurled(
      landmarks,
      pinkyMcp,
      pinkyPip,
      pinkyDip,
      pinkyTip,
    );

    return indexCurled && middleCurled && ringCurled && pinkyCurled;
  }

  /// Calculate distance between two landmarks
  static double _distance(Landmark a, Landmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final dz = (a.z ?? 0) - (b.z ?? 0);
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Calculate angle at point B
  static double _calculateAngle(Landmark a, Landmark b, Landmark c) {
    final ab = math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
    final bc = math.sqrt(math.pow(c.x - b.x, 2) + math.pow(c.y - b.y, 2));
    final ac = math.sqrt(math.pow(c.x - a.x, 2) + math.pow(c.y - a.y, 2));

    final cosAngle = (ab * ab + bc * bc - ac * ac) / (2 * ab * bc);
    final clampedCos = cosAngle.clamp(-1.0, 1.0);

    return math.acos(clampedCos) * 180 / math.pi;
  }
}
