
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/table_bot/application/ble_connection_notifier.dart';

/// A screen that displays the connection status to the TableBot and its
/// live telemetry data.
///
/// This widget watches the [bleConnectionProvider] and rebuilds its UI
/// based on the connection state (loading, error, or data received).
class TableBotConnectionScreen extends ConsumerWidget {
  const TableBotConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TableBot Status'),
      ),
      body: Center(
        child: bleState.when(
          // While connecting or scanning, show a loading indicator.
          loading: () => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning for TableBot...'),
            ],
          ),
          // If an error occurs, display the error message.
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
          // When data is received, display the telemetry.
          data: (tableBot) {
            if (tableBot == null) {
              // This can happen if the provider is in a data state but has null data,
              // for example, during initialization before the first telemetry packet arrives.
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connected. Waiting for telemetry...'),
                ],
              );
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
                  // Display charging status based on the boolean flags.
                  if (tableBot.isCharging)
                    const Chip(label: Text('Charging'), backgroundColor: Colors.orange),
                  if (tableBot.isFullyCharged)
                    const Chip(label: Text('Fully Charged'), backgroundColor: Colors.green),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
