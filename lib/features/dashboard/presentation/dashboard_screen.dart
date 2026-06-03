
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/table_bot/application/ble_connection_notifier.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TableBot Dashboard'),
      ),
      body: Center(
        child: bleState.when(
          data: (tableBot) {
            if (tableBot == null) {
              return const Text('No data available.');
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('State: ${tableBot.state}', style: Theme.of(context).textTheme.titleLarge),
                  Text('Mode: ${tableBot.mode}', style: Theme.of(context).textTheme.titleLarge),
                  Text('Battery: ${tableBot.battery}%', style: Theme.of(context).textTheme.titleLarge),
                  Text('Temperature: ${tableBot.temp.toStringAsFixed(1)}°C', style: Theme.of(context).textTheme.titleLarge),
                  Text('WiFi Status: ${tableBot.wifi}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  if (tableBot.isCharging)
                    const Chip(label: Text('Charging'), backgroundColor: Colors.orange),
                  if (tableBot.isFullyCharged)
                    const Chip(label: Text('Fully Charged'), backgroundColor: Colors.green),
                ],
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        ),
      ),
    );
  }
}
