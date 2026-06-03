
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDevice {
  final String name;
  final BluetoothDevice device;
  final String? license;

  BleDevice({required this.name, required this.device, this.license});
}
