
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:myapp/features/ble_connectivity/application/ble_provider.dart';
import 'package:myapp/features/device_control/presentation/device_screen.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(bleProvider.notifier).startScan();
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleProvider);

    ref.listen(bleProvider, (previous, next) {
      if (next.connectedDevice != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DeviceScreen(),
          ),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/radar.json', width: 250, height: 250),
            const SizedBox(height: 24),
            Text(
              'Searching for TableBot...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            if (bleState.discoveredDevices.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: bleState.discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = bleState.discoveredDevices[index];
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.device.remoteId.toString()),
                      onTap: () {
                        ref.read(bleProvider.notifier).connect(device.device);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
