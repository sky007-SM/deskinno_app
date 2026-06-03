
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/dashboard/presentation/dashboard_screen.dart';
import 'package:myapp/features/simulation/application/simulation_provider.dart';
import 'package:myapp/features/table_bot/application/ble_connection_notifier.dart';
import 'package:myapp/features/table_bot/presentation/table_bot_connection_screen.dart';

class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMockMode = ref.watch(simulationModeProvider);
    final bleConnection = ref.watch(bleConnectionProvider);

    // If mock mode is enabled, show the dashboard.
    if (isMockMode) {
      return const DashboardScreen();
    }

    // If we have a connection, show the dashboard.
    // We check for the data property being non-null, which indicates a successful connection and data stream.
    if (bleConnection.hasValue && bleConnection.value != null) {
      return const DashboardScreen();
    }
    
    // Otherwise, show the connection/provisioning screen.
    return const TableBotConnectionScreen();
  }
}
