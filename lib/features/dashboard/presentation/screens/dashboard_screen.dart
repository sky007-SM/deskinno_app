import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/dashboard/presentation/widgets/mode_idle_view.dart';
import 'package:myapp/features/dashboard/presentation/widgets/mode_focus_view.dart';
import 'package:myapp/features/dashboard/presentation/widgets/game_view.dart';
import 'package:myapp/features/device_control/application/telemetry_provider.dart';
import 'package:myapp/features/device_control/domain/telemetry.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TableBot Dashboard'),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 2 / 1,
          child: Container(
            color: Colors.black,
            child: telemetry?.when(
              data: (telemetryData) {
                if (telemetryData == null) {
                  return const Center(
                    child: Text('Waiting for data...',
                        style: TextStyle(color: Colors.white)),
                  );
                }
                switch (telemetryData.mode) {
                  case 0: // MODE_IDLE
                    return const IdleView();
                  case 1: // MODE_FOCUS
                    return const FocusView();
                  case 2: // MODE_GAME
                    return const GameView();
                  default:
                    return const Center(
                      child: Text('Unknown Mode',
                          style: TextStyle(color: Colors.white)),
                    );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: Colors.red))),
            ),
          ),
        ),
      ),
    );
  }
}

extension on Telemetry? {
  Widget? when(
      {required Widget Function(dynamic telemetryData) data,
      required Center Function() loading,
      required Center Function(dynamic err, dynamic stack) error}) {
    return null;
  }
}
