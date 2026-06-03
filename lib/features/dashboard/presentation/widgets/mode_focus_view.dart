import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:myapp/features/device_control/application/clock_provider.dart';

class FocusView extends ConsumerWidget {
  const FocusView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(clockProvider);

    return CustomPaint(
      painter: _FocusPainter(time: time.value),
      child: Container(),
    );
  }
}

class _FocusPainter extends CustomPainter {
  final DateTime? time;

  _FocusPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    // Giant Centered Clock
    final timeString = time != null ? DateFormat('HH:mm').format(time!) : '--:--';
    final textPainter = TextPainter(
      text: TextSpan(
        text: timeString,
        style: const TextStyle(fontSize: 50, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final x = (size.width - textPainter.width) / 2;
    textPainter.paint(canvas, Offset(x, 42));

    // Micro-Eyes Accent
    const leftEye = Offset(44, 14);
    const rightEye = Offset(84, 14);
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(leftEye, 6, paint);
    canvas.drawCircle(rightEye, 6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
