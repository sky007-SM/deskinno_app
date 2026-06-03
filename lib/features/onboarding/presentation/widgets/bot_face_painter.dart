import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vm;

class BotFacePainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0 for boot-up
  final double idleAnimationValue; // 0.0 to 1.0 for idle loop

  BotFacePainter(
      {required this.animationValue, required this.idleAnimationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint glowPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6.0);

    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Establish virtual coordinate system
    const double virtualWidth = 128.0;
    const double virtualHeight = 64.0;
    final double scaleX = size.width / virtualWidth;
    final double scaleY = size.height / virtualHeight;
    final scaleMatrix = Matrix4.identity()
      ..scaleByVector3(vm.Vector3(scaleX, scaleY, 1.0));

    // Define paths based on virtual coordinates from airules.md
    final RRect borderRing = RRect.fromLTRBR(
        0, 0, virtualWidth, virtualHeight, const Radius.circular(8.0));
    final Path borderPath = Path()..addRRect(borderRing);

    const double leftEyeX = 38.0,
        rightEyeX = 90.0,
        eyeY = 27.0,
        eyeRadius = 11.0;
    final Path leftEyePath = Path()
      ..addOval(Rect.fromCircle(
          center: const Offset(leftEyeX, eyeY), radius: eyeRadius));
    final Path rightEyePath = Path()
      ..addOval(Rect.fromCircle(
          center: const Offset(rightEyeX, eyeY), radius: eyeRadius));

    // --- Boot Animation ---
    final Path scaledBorderPath = borderPath.transform(scaleMatrix.storage);
    final Path scaledLeftEyePath = leftEyePath.transform(scaleMatrix.storage);
    final Path scaledRightEyePath = rightEyePath.transform(scaleMatrix.storage);

    if (animationValue < 1.0) {
      // Phase 1: Draw Border (0.0 to 0.5)
      if (animationValue > 0) {
        final double borderProgress = (animationValue * 2).clamp(0.0, 1.0);
        final ui.PathMetrics pathMetrics = scaledBorderPath.computeMetrics();
        for (final ui.PathMetric metric in pathMetrics) {
          final Path extractedPath =
              metric.extractPath(0.0, metric.length * borderProgress);
          canvas.drawPath(extractedPath, glowPaint);
          canvas.drawPath(extractedPath, paint);
        }
      }

      // Phase 2: Draw Eyes (0.5 to 1.0)
      if (animationValue > 0.5) {
        final double eyesProgress =
            ((animationValue - 0.5) * 2).clamp(0.0, 1.0);
        // Left Eye
        final ui.PathMetrics leftEyeMetrics =
            scaledLeftEyePath.computeMetrics();
        for (final ui.PathMetric metric in leftEyeMetrics) {
          final Path extractedPath =
              metric.extractPath(0.0, metric.length * eyesProgress);
          canvas.drawPath(extractedPath, glowPaint);
          canvas.drawPath(extractedPath, paint);
        }
        // Right Eye
        final ui.PathMetrics rightEyeMetrics =
            scaledRightEyePath.computeMetrics();
        for (final ui.PathMetric metric in rightEyeMetrics) {
          final Path extractedPath =
              metric.extractPath(0.0, metric.length * eyesProgress);
          canvas.drawPath(extractedPath, glowPaint);
          canvas.drawPath(extractedPath, paint);
        }
      }
    } else {
      // --- Idle Animation ---
      canvas.drawPath(scaledBorderPath, glowPaint);
      canvas.drawPath(scaledBorderPath, paint);
      canvas.drawPath(scaledLeftEyePath, paint);
      canvas.drawPath(scaledRightEyePath, paint);

      // Pupil Tracking
      final double pupilOffsetX =
          sin(idleAnimationValue * 2 * pi) * 3.0; // X = [-3, 3]
      final double pupilOffsetY =
          cos(idleAnimationValue * 4 * pi) * 2.0; // Y = [-2, 2]

      final leftPupilCenter = Offset(
          (leftEyeX + pupilOffsetX) * scaleX, (eyeY + pupilOffsetY) * scaleY);
      final rightPupilCenter = Offset(
          (rightEyeX + pupilOffsetX) * scaleX, (eyeY + pupilOffsetY) * scaleY);
      const double pupilRadius = 2.5;

      canvas.drawCircle(leftPupilCenter, pupilRadius * scaleX, fillPaint);
      canvas.drawCircle(rightPupilCenter, pupilRadius * scaleX, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BotFacePainter oldDelegate) =>
      animationValue != oldDelegate.animationValue ||
      idleAnimationValue != oldDelegate.idleAnimationValue;
}
