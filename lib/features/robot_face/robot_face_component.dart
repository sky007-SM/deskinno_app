
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── ENUMS & IMMUTABLE STATE ──────────────────────────────────────────────────
enum TargetExpression { happy, sad, sleepy, focused, neutral }

@immutable
class RobotFaceState {
  final TargetExpression targetExpression;
  final int pupilX;
  final int pupilY;
  final int blinkStage;
  final bool isBlinking;
  final bool isAnimating;

  const RobotFaceState({
    required this.targetExpression,
    this.pupilX = 0,
    this.pupilY = 0,
    this.blinkStage = 0,
    this.isBlinking = false,
    this.isAnimating = true,
  });

  RobotFaceState copyWith({
    TargetExpression? targetExpression,
    int? pupilX,
    int? pupilY,
    int? blinkStage,
    bool? isBlinking,
    bool? isAnimating,
  }) {
    return RobotFaceState(
      targetExpression: targetExpression ?? this.targetExpression,
      pupilX: pupilX ?? this.pupilX,
      pupilY: pupilY ?? this.pupilY,
      blinkStage: blinkStage ?? this.blinkStage,
      isBlinking: isBlinking ?? this.isBlinking,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

// ── RIVERPOD NOTIFIER (THE ENGINE) ───────────────────────────────────────────
class RobotFaceNotifier extends AutoDisposeNotifier<RobotFaceState> {
  Timer? _tickTimer;
  Timer? _pupilTimer;
  bool _blinkOpen = false;
  bool _blinkDone = true;

  @override
  RobotFaceState build() {
    _startTickTimer();
    _scheduleNextPupilWander();

    ref.onDispose(() {
      _tickTimer?.cancel();
      _pupilTimer?.cancel();
    });

    return const RobotFaceState(targetExpression: TargetExpression.happy);
  }

  void _startTickTimer() {
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.isBlinking) {
        _handleBlinkStep();
      }
    });
  }

  void _scheduleNextPupilWander() {
    final randomWait = 1500 + math.Random().nextInt(2000);
    _pupilTimer = Timer(Duration(milliseconds: randomWait), () {
      state = state.copyWith(
        pupilX: math.Random().nextInt(7) - 3, // random(-3, 3)
        pupilY: math.Random().nextInt(5) - 2, // random(-2, 2)
      );
      _scheduleNextPupilWander();
    });
  }

  void _handleBlinkStep() {
    int currentStage = state.blinkStage;
    bool currentlyBlinking = state.isBlinking;

    if (_blinkDone) {
      _blinkDone = false;
      currentStage = 0;
      _blinkOpen = false;
    }

    if (!_blinkOpen) {
      currentStage++;
      if (currentStage > 2) {
        _blinkOpen = true;
        currentStage = 1;
      }
    } else {
      currentStage--;
      if (currentStage < 0) {
        _blinkDone = true;
        currentlyBlinking = false;
      }
    }

    state = state.copyWith(blinkStage: currentStage, isBlinking: currentlyBlinking);
  }

  void setExpression(TargetExpression expression) {
    state = state.copyWith(targetExpression: expression);
  }

  void triggerBlink() {
    if (!state.isBlinking) {
      _blinkDone = true;
      state = state.copyWith(isBlinking: true);
    }
  }
}

// Provider Declaration
final robotFaceProvider = NotifierProvider.autoDispose<RobotFaceNotifier, RobotFaceState>(
  () => RobotFaceNotifier(),
);

// ── RENDER CONSUMER WIDGET ───────────────────────────────────────────────────
class RiverpodRobotFace extends ConsumerWidget {
  const RiverpodRobotFace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faceState = ref.watch(robotFaceProvider);

    return AspectRatio(
      aspectRatio: 128 / 64,
      child: Container(
        color: const Color(0xff050505),
        child: CustomPaint(
          painter: _FacePainter(
            expression: faceState.targetExpression,
            pupilX: faceState.pupilX,
            pupilY: faceState.pupilY,
            blinkStage: faceState.blinkStage,
          ),
        ),
      ),
    );
  }
}

// ── CUSTOM PAINTER ───────────────────────────────────────────────────────────
class _FacePainter extends CustomPainter {
  final TargetExpression expression;
  final int pupilX;
  final int pupilY;
  final int blinkStage;

  _FacePainter({
    required this.expression,
    required this.pupilX,
    required this.pupilY,
    required this.blinkStage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 128.0;
    final Paint onPaint = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.fill;
    final Paint offPaint = Paint()..color = const Color(0xff050505)..style = PaintingStyle.fill;
    final Paint linePaint = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    canvas.save();
    canvas.scale(scale);

    // Background Fill
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 64), offPaint);

    // Border Ring
    final RRect borderRing = RRect.fromLTRBR(0, 0, 128, 64, const Radius.circular(8.0));
    canvas.drawRRect(borderRing, linePaint);

    // Eye Coordinates
    const double leftEyeX = 38.0, rightEyeX = 90.0, eyeY = 27.0, eyeRadius = 11.0;

    // Draw Eyes
    _drawEye(canvas, onPaint, linePaint, offPaint, leftEyeX, eyeY, eyeRadius);
    _drawEye(canvas, onPaint, linePaint, offPaint, rightEyeX, eyeY, eyeRadius);

    // Draw Mouth
    switch (expression) {
      case TargetExpression.happy:
        _drawMouth(canvas, linePaint, smile: true);
        break;
      case TargetExpression.sad:
        _drawMouth(canvas, linePaint, smile: false);
        break;
      case TargetExpression.neutral:
        _drawMouthWavy(canvas, linePaint);
        _drawQuestionMark(canvas, onPaint);
        break;
      case TargetExpression.focused:
        _drawMouth(canvas, linePaint, smile: true, flat: true);
        break;
      case TargetExpression.sleepy:
        // No mouth for sleepy
        break;
    }
    
    canvas.restore();
  }

  void _drawEye(Canvas canvas, Paint onPaint, Paint linePaint, Paint offPaint, double cx, double cy, double radius) {
    final Path eyePath = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawPath(eyePath, linePaint);

    // Pupil
    const double pupilRadius = 2.5;
    final double finalPupilX = cx + pupilX;
    final double finalPupilY = cy + pupilY;
    canvas.drawCircle(Offset(finalPupilX, finalPupilY), pupilRadius, onPaint);

    // Eyelid for Blinking & Sleepy Expression
    double lidHeight = 0;
    if (expression == TargetExpression.sleepy) {
      lidHeight = radius * 1.5;
    } else if (blinkStage > 0) {
      lidHeight = radius * 2.2 * (blinkStage / 2.0); // 2 is max blinkStage
    }

    if (lidHeight > 0) {
      final Rect eyeRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      final Path lidPath = Path()..addRect(Rect.fromLTWH(eyeRect.left - 1, eyeRect.top - 1, eyeRect.width + 2, lidHeight));
      
      canvas.drawPath(Path.combine(ui.PathOperation.intersect, eyePath, lidPath), offPaint);
      
      final lidLineY = eyeRect.top + lidHeight - 1.5;
      canvas.drawLine(Offset(eyeRect.left, lidLineY), Offset(eyeRect.right, lidLineY), linePaint);
    }
  }

  void _drawMouth(Canvas canvas, Paint paint, {required bool smile, bool flat = false}) {
    final path = Path();
    if (flat) {
      path.moveTo(54, 48);
      path.lineTo(74, 48);
    } else {
      final double startY = smile ? 46 : 52;
      final double endY = smile ? 46 : 52;
      final double controlY = smile ? 54 : 44;
      path.moveTo(54, startY);
      path.quadraticBezierTo(64, controlY, 74, endY);
    }
    canvas.drawPath(path, paint);
  }

  void _drawMouthWavy(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(54, 49)
      ..quadraticBezierTo(59, 45, 64, 49)
      ..quadraticBezierTo(69, 53, 74, 49);
    canvas.drawPath(path, paint);
  }

  void _drawQuestionMark(Canvas canvas, Paint paint) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(color: paint.color, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr
    )..layout();
    textPainter.paint(canvas, const Offset(110, 18));
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.expression != expression ||
        oldDelegate.pupilX != pupilX ||
        oldDelegate.pupilY != pupilY ||
        oldDelegate.blinkStage != blinkStage;
  }
}
