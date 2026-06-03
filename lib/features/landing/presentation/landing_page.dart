import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/developer_mode/application/developer_mode_provider.dart';
import 'package:myapp/features/root_gate/presentation/root_gate.dart';
import 'package:myapp/features/simulation/application/simulation_provider.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  int _tapCount = 0;
  DateTime? _firstTapTime;

  void _handleTap() {
    final now = DateTime.now();
    _firstTapTime ??= now;

    if (now.difference(_firstTapTime!).inSeconds > 2) {
      _tapCount = 0;
      _firstTapTime = null;
    } else {
      _tapCount++;
      if (_tapCount == 5) {
        ref.read(developerModeProvider.notifier).toggle();
        _tapCount = 0;
        _firstTapTime = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloperMode = ref.watch(developerModeProvider);

    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        child: const Center(
          child: Text(
            'TableBot',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButton: isDeveloperMode
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(simulationModeProvider.notifier).setMode(true);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const RootGate(),
                  ),
                );
              },
              label: const Text('Launch Mock Mode (Simulated Hardware)'),
            )
          : null,
    );
  }
}
