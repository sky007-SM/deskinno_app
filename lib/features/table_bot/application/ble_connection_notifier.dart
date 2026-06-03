import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/simulation/application/simulation_provider.dart';
import 'package:myapp/features/table_bot/domain/table_bot_model.dart';

/// Provides an [AsyncNotifier] to manage the Bluetooth Low Energy connection
/// and communication with the TableBot.
final bleConnectionProvider =
    AsyncNotifierProvider<BleConnectionNotifier, TableBot?>(() {
      return BleConnectionNotifier();
    });

/// An [AsyncNotifier] that handles the entire lifecycle of connecting to,
/// communicating with, and parsing data from the TableBot via BLE.
///
/// It automatically scans for the device, connects, handles handshakes,
/// listens for telemetry data, and manages a command queue for sending data
/// back to the device.
class BleConnectionNotifier extends AsyncNotifier<TableBot?> {
  // BLE properties
  BluetoothDevice? _device;
  StreamSubscription<List<int>>? _statusSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // Command queue properties
  final List<String> _commandQueue = [];
  Timer? _commandTimer;

  // Mock data timer
  Timer? _mockDataTimer;

  // TableBot specific BLE UUIDs and name
  final String _deviceBroadcastName = 'TableBot';
  final Guid _serviceUuid = Guid('12345678-1234-1234-1234-123456789abc');
  final Guid _statusCharacteristicUuid = Guid(
    '12345678-1234-1234-1234-123456789abe',
  );
  final Guid _commandCharacteristicUuid = Guid(
    '12345678-1234-1234-1234-123456789abf',
  );

  @override
  Future<TableBot?> build() async {
    // Set up cleanup logic for when the provider is disposed.
    ref.onDispose(() {
      _statusSubscription?.cancel();
      _connectionStateSubscription?.cancel();
      _scanSubscription?.cancel();
      _commandTimer?.cancel();
      _mockDataTimer?.cancel();
      _device?.disconnect();
      FlutterBluePlus.stopScan();
    });

    if (ref.watch(simulationModeProvider)) {
      _startMockDataStream();
      return null;
    }

    _startCommandTimer();

    // Listen for adapter state changes to start/stop scanning.
    final adapterStateSubscription = FlutterBluePlus.adapterState.listen((
      state,
    ) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      } else {
        _scanSubscription?.cancel();
        this.state = AsyncValue.error(
          'Bluetooth is turned off. Please turn it on.',
          StackTrace.current,
        );
      }
    });
    ref.onDispose(adapterStateSubscription.cancel);

    // Initial check to see if Bluetooth is on.
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      return Future.error(
        'Bluetooth is turned off. Please turn it on.',
        StackTrace.current,
      );
    }

    _startScan();
    return null; // Initial state is loading, will be updated by streams.
  }

  /// Scans for the TableBot device.
  void _startScan() {
    FlutterBluePlus.stopScan(); // Ensure any previous scan is stopped.

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      try {
        final discoveredDevice = results.firstWhere(
          (r) => r.device.platformName == _deviceBroadcastName,
        );

        if (discoveredDevice.device != _device ||
            !(_device?.isConnected ?? false)) {
          _device = discoveredDevice.device;
          FlutterBluePlus.stopScan();
          _connect();
        }
      } on StateError {
        // This is expected and okay, just means we haven't found the device yet.
      } catch (e, s) {
        state = AsyncValue.error(e, s);
      }
    });

    FlutterBluePlus.startScan(
      withServices: [_serviceUuid],
      timeout: const Duration(seconds: 15),
    );
  }

  /// Connects to the discovered device and sets up connection state listener.
  Future<void> _connect() async {
    if (_device == null) return;

    state = const AsyncLoading();

    _connectionStateSubscription = _device!.connectionState.listen((event) {
      if (event == BluetoothConnectionState.disconnected) {
        state = AsyncValue.error(
          'Device disconnected. Re-scanning...',
          StackTrace.current,
        );
        _statusSubscription?.cancel();
        _startScan();
      }
    });

    try {
      await _device!.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 15),
        license: License.nonprofit,
      );
      await _device!.requestMtu(512);
      await _subscribeToStatus();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      _startScan();
    }
  }

  /// Subscribes to the status characteristic to receive telemetry data.
  Future<void> _subscribeToStatus() async {
    if (_device == null) return;
    try {
      final services = await _device!.discoverServices();
      final service = services.firstWhere((s) => s.uuid == _serviceUuid);
      final statusCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid == _statusCharacteristicUuid,
      );

      await statusCharacteristic.setNotifyValue(true);
      _statusSubscription = statusCharacteristic.lastValueStream.listen(
        (value) {
          final telemetryString = utf8.decode(value);
          if (telemetryString == "ALERT:BATTERY_CRITICAL") {
            state = AsyncValue.error("CRITICAL BATTERY", StackTrace.current);
          } else {
            state = AsyncValue.data(TableBot.fromString(telemetryString));
          }
        },
        onError: (error, stackTrace) {
          state = AsyncValue.error(error, stackTrace);
        },
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  /// Adds a command to the queue to be sent to the TableBot.
  void sendCommand(String command) {
    if (command.length > 31) {
      return;
    }
    _commandQueue.add(command);
  }

  /// Starts a periodic timer to process the command queue.
  void _startCommandTimer() {
    _commandTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_commandQueue.isNotEmpty && (_device?.isConnected ?? false)) {
        _writeCommand(_commandQueue.removeAt(0));
      }
    });
  }

  /// Writes a command to the command characteristic.
  Future<void> _writeCommand(String command) async {
    if (_device == null) return;
    try {
      final services = await _device!.discoverServices();
      final service = services.firstWhere((s) => s.uuid == _serviceUuid);
      final commandCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid == _commandCharacteristicUuid,
      );

      await commandCharacteristic.write(
        utf8.encode(command),
        withoutResponse: true,
      );
    } catch (e) {
      // Don't disrupt the main state for a single failed command if not critical
    }
  }

  // ================== Mock Data Generation ==================

  void _startMockDataStream() {
    state = const AsyncLoading();
    _mockDataTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final mockData = _generateMockTelemetry();
      state = AsyncValue.data(TableBot.fromString(mockData));
    });
    // Immediately provide a first data point
    final mockData = _generateMockTelemetry();
    state = AsyncValue.data(TableBot.fromString(mockData));
  }

  String _generateMockTelemetry() {
    final random = Random();
    final state = random.nextInt(5); // 0-4
    final mode = random.nextInt(3); // 0-2
    final battery = random.nextInt(101); // 0-100
    final temp = 18.0 + random.nextDouble() * 10.0; // 18.0 - 28.0
    final wifi = random.nextBool() ? 1 : 0;
    return 'STATE:$state|MODE:$mode|BAT:$battery|TEMP:${temp.toStringAsFixed(1)}|WIFI:$wifi';
  }
}
