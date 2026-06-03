
import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/ble_connectivity/domain/ble_device.dart';

final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  return BleNotifier();
});

class BleState {
  final List<BleDevice> discoveredDevices;
  final BluetoothDevice? connectedDevice;
  final BluetoothCharacteristic? statusCharacteristic;
  final BluetoothCharacteristic? commandCharacteristic;

  BleState({
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.statusCharacteristic,
    this.commandCharacteristic,
  });

  BleState copyWith({
    List<BleDevice>? discoveredDevices,
    BluetoothDevice? connectedDevice,
    BluetoothCharacteristic? statusCharacteristic,
    BluetoothCharacteristic? commandCharacteristic,
  }) {
    return BleState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      statusCharacteristic: statusCharacteristic ?? this.statusCharacteristic,
      commandCharacteristic: commandCharacteristic ?? this.commandCharacteristic,
    );
  }
}

class BleNotifier extends StateNotifier<BleState> {
  BleNotifier() : super(BleState());

  Future<void> startScan() async {
    state = state.copyWith(discoveredDevices: []);
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName.isNotEmpty) {
          final device = BleDevice(name: r.device.platformName, device: r.device, license: 'nonprofit');
          if (!state.discoveredDevices.any((d) => d.device.remoteId == device.device.remoteId)) {
            state = state.copyWith(discoveredDevices: [...state.discoveredDevices, device]);
          }
        }
      }
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    await stopScan();
    await device.connect(license: License.nonprofit);
    state = state.copyWith(connectedDevice: device);
    await _discoverServices(device);
  }

  Future<void> disconnect() async {
    if (state.connectedDevice != null) {
      await state.connectedDevice!.disconnect();
      state = BleState();
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == '12345678-1234-1234-1234-123456789abe') {
          state = state.copyWith(statusCharacteristic: characteristic);
          await characteristic.setNotifyValue(true);
        } else if (characteristic.uuid.toString() == '12345678-1234-1234-1234-123456789abd') {
          state = state.copyWith(commandCharacteristic: characteristic);
        }
      }
    }
  }

  Future<void> sendCommand(String command) async {
    if (state.commandCharacteristic != null) {
      await state.commandCharacteristic!.write(utf8.encode(command));
    }
  }
}
