
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/ble_connectivity/application/ble_provider.dart';
import 'package:myapp/features/device_control/domain/telemetry.dart';

final telemetryProvider = StateNotifierProvider<TelemetryNotifier, Telemetry?>((ref) {
  return TelemetryNotifier(ref);
});

class TelemetryNotifier extends StateNotifier<Telemetry?> {
  final Ref _ref;
  StreamSubscription? _subscription;

  TelemetryNotifier(this._ref) : super(null) {
    _ref.listen(bleProvider, (previous, next) {
      if (next.statusCharacteristic != null) {
        _subscription = next.statusCharacteristic!.lastValueStream.listen((value) {
          final data = utf8.decode(value);
          state = Telemetry.fromString(data);
        });
      } else {
        _subscription?.cancel();
        state = null;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
