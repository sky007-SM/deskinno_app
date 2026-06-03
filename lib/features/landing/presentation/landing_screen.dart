
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/ble_connectivity/application/ble_provider.dart';
import 'package:myapp/features/ble_connectivity/domain/ble_device.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(bleProvider.notifier).startScan(),
          )
        ],
      ),
      body: Center(
        child: bleState.connectedDevice == null
            ? _buildDeviceList(ref, bleState)
            : _buildConnectedDevice(ref, bleState),
      ),
    );
  }

  Widget _buildDeviceList(WidgetRef ref, BleState bleState) {
    if (bleState.discoveredDevices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Scanning for devices...'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: bleState.discoveredDevices.length,
      itemBuilder: (context, index) {
        BleDevice device = bleState.discoveredDevices[index];
        return ListTile(
          title: Text(device.name),
          subtitle: Text(device.device.remoteId.toString()),
          onTap: () => ref.read(bleProvider.notifier).connect(device.device),
        );
      },
    );
  }

  Widget _buildConnectedDevice(WidgetRef ref, BleState bleState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Connected to ${bleState.connectedDevice!.platformName}'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => ref.read(bleProvider.notifier).disconnect(),
          child: const Text('Disconnect'),
        ),
        const SizedBox(height: 20),
        _buildCommandSender(ref, bleState),
      ],
    );
  }

  Widget _buildCommandSender(WidgetRef ref, BleState bleState) {
    final textController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Enter command',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                ref
                    .read(bleProvider.notifier)
                    .sendCommand(textController.text);
              }
            },
            child: const Text('Send Command'),
          ),
          const SizedBox(height: 20),
          _buildStatusMonitor(ref, bleState)
        ],
      ),
    );
  }

  Widget _buildStatusMonitor(WidgetRef ref, BleState bleState) {
    if (bleState.statusCharacteristic == null) {
      return const Text('Status characteristic not found');
    }

    return StreamBuilder<List<int>>(
      stream: bleState.statusCharacteristic!.lastValueStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = String.fromCharCodes(snapshot.data!);
          return Text('Status: $data');
        } else {
          return const Text('Listening for status updates...');
        }
      },
    );
  }
}
