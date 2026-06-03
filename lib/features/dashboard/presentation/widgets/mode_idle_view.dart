import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:myapp/features/device_control/application/clock_provider.dart';
import 'package:myapp/features/device_control/application/telemetry_provider.dart';
import 'package:myapp/features/device_control/domain/telemetry.dart';

class IdleView extends ConsumerWidget {
  const IdleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final time = ref.watch(clockProvider);

    return CustomPaint(
      painter: _IdlePainter(telemetry: telemetry, time: time.value),
      child: Container(),
    );
  }
}

class _IdlePainter extends CustomPainter {
  final Telemetry? telemetry;
  final DateTime? time;

  _IdlePainter({required this.telemetry, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke;

    // Sub-Frame Face Enclosure
    final faceRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 12, 92, 48),
      const Radius.circular(8),
    );
    canvas.drawRRect(faceRect, paint);

    // Mini-Eye Anchors
    const leftEye = Offset(45, 32);
    const rightEye = Offset(83, 32);
    canvas.drawCircle(leftEye, 9, paint);
    canvas.drawCircle(rightEye, 9, paint);

    // Cheek Circles
    const leftCheek = Offset(30, 44);
    const rightCheek = Offset(98, 44);
    canvas.drawCircle(leftCheek, 3, paint);
    canvas.drawCircle(rightCheek, 3, paint);

    if (telemetry?.faceExpression == 1) { // FACE_NEUTRAL
      // Wavy Mouth
      final mouthPath = Path();
      mouthPath.moveTo(40, 50);
      mouthPath.quadraticBezierTo(65, 40, 90, 50);
      canvas.drawPath(mouthPath, paint);

      // Question Mark
      final questionPainter = TextPainter(
        text: const TextSpan(
          text: '?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      questionPainter.layout();
      questionPainter.paint(canvas, const Offset(110, 20));
    }

    // Time
    final timeString = time != null ? DateFormat('HH:mm').format(time!) : '--:--';
    final timePainter = TextPainter(
      text: TextSpan(
        text: timeString,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    timePainter.layout();
    timePainter.paint(canvas, const Offset(0, 10));

    // Temperature
    final tempPainter = TextPainter(
      text: TextSpan(
        text: '${telemetry?.temp.toStringAsFixed(1) ?? '-'}°C',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    tempPainter.layout();
    tempPainter.paint(canvas, const Offset(94, 10));

    // BLE Status Connection Dot
    if (telemetry?.showBLEIcon ?? false) {
      final blePaint = Paint()..color = Colors.blue;
      canvas.drawCircle(const Offset(122, 5), 3, blePaint);
    }

    // Battery Low Warning Symbol
    if (telemetry?.showBatteryIcon ?? false) {
      final batteryWarnPainter = TextPainter(
        text: const TextSpan(
          text: '!',
          style: TextStyle(color: Colors.red, fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      );
      batteryWarnPainter.layout();
      batteryWarnPainter.paint(canvas, const Offset(0, 44));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
