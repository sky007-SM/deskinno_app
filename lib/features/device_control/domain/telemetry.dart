
class Telemetry {
  final int state;
  final int mode;
  final int bat;
  final double temp;
  final int wifi;
  final int faceExpression;
  final bool isCharging;
  final bool isChargeComplete;

  Telemetry({
    required this.state,
    required this.mode,
    required this.bat,
    required this.temp,
    required this.wifi,
    this.faceExpression = 0,
    this.isCharging = false,
    this.isChargeComplete = false,
  });

  // The spec is ambiguous about whether these are sent from the device
  // or derived on the client. We will derive them for now.
  bool get showBLEIcon => true; // Always show while connected
  bool get showBatteryIcon => bat < 10;

  factory Telemetry.fromString(String data) {
    final parts = data.split('|');
    final Map<String, String> values = {};
    for (var part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        values[keyValue[0]] = keyValue[1];
      }
    }

    return Telemetry(
      state: int.parse(values['STATE'] ?? '0'),
      mode: int.parse(values['MODE'] ?? '0'),
      bat: int.parse(values['BAT'] ?? '0'),
      temp: double.parse(values['TEMP'] ?? '0.0'),
      wifi: int.parse(values['WIFI'] ?? '0'),
      faceExpression: int.parse(values['FACE'] ?? '0'),
    );
  }

  Telemetry copyWith({
    int? state,
    int? mode,
    int? bat,
    double? temp,
    int? wifi,
    int? faceExpression,
    bool? isCharging,
    bool? isChargeComplete,
  }) {
    return Telemetry(
      state: state ?? this.state,
      mode: mode ?? this.mode,
      bat: bat ?? this.bat,
      temp: temp ?? this.temp,
      wifi: wifi ?? this.wifi,
      faceExpression: faceExpression ?? this.faceExpression,
      isCharging: isCharging ?? this.isCharging,
      isChargeComplete: isChargeComplete ?? this.isChargeComplete,
    );
  }
}
