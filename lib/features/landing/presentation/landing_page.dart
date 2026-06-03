
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/ble_connectivity/application/ble_provider.dart';
import 'package:myapp/features/developer_mode/application/developer_mode_provider.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleProvider);
    final isDevMode = ref.watch(developerModeEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TableBot'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (bleState.connectedDevice != null)
              Text(
                'Connected to: ${bleState.connectedDevice!.platformName}',
              )
            else
              const Text('Not connected'),
            if (isDevMode)
              const Text(
                'Developer Mode Enabled',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
