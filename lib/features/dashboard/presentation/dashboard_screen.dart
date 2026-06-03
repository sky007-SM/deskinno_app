
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/device_control/application/telemetry_provider.dart';
import 'package:myapp/features/dashboard/presentation/widgets/mode_idle_view.dart';
import 'package:myapp/features/dashboard/presentation/widgets/mode_focus_view.dart';
import 'package:myapp/features/dashboard/presentation/widgets/mode_game_view.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TableBot Controller'),
        centerTitle: true,
        actions: [
          if (telemetry != null && telemetry.isCharging)
            const Icon(Icons.bolt)
          else if (telemetry != null && telemetry.isChargeComplete)
            const Icon(Icons.battery_full),
          const SizedBox(width: 16),
        ],
      ),
      body: telemetry == null
          ? const Center(child: CircularProgressIndicator())
          : _buildViewForMode(telemetry.mode),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Battery: ${telemetry?.bat ?? '-'}%'),
            Text('State: ${telemetry?.state ?? '-'}'),
            Text('WiFi: ${telemetry?.wifi ?? '-'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildViewForMode(int? mode) {
    switch (mode) {
      case 0: // MODE_IDLE
        return const IdleView();
      case 1: // MODE_FOCUS
        return const FocusView();
      case 2: // MODE_GAME
        return const GameView();
      default:
        return const Center(child: Text('Unknown Mode'));
    }
  }
}
