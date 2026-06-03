
/// Represents the state of the TableBot.
class TableBot {
  final int state;
  final int mode;
  final int battery;
  final double temp;
  final int wifi;
  final bool isCharging;
  final bool isFullyCharged;

  TableBot({
    required this.state,
    required this.mode,
    required this.battery,
    required this.temp,
    required this.wifi,
    required this.isCharging,
    required this.isFullyCharged,
  });

  factory TableBot.fromString(String telemetry) {
    int state = 0;
    int mode = 0;
    int battery = 0;
    double temp = 0.0;
    int wifi = 0;

    final parts = telemetry.split('|');
    for (var part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0];
        final value = keyValue[1];
        switch (key) {
          case 'STATE':
            state = int.tryParse(value) ?? 0;
            break;
          case 'MODE':
            mode = int.tryParse(value) ?? 0;
            break;
          case 'BAT':
            battery = int.tryParse(value) ?? 0;
            break;
          case 'TEMP':
            temp = double.tryParse(value) ?? 0.0;
            break;
          case 'WIFI':
            wifi = int.tryParse(value) ?? 0;
            break;
        }
      }
    }

    // This is a placeholder for the actual charging logic from GPIO pins.
    // Since we don't have access to the pins from the app, we'll
    // have to rely on the telemetry string for this information.
    // We will assume for now that the ESP32 will send this information.
    // If not, we will need to update this logic.
    const isCharging = false;
    const isFullyCharged = false;

    return TableBot(
      state: state,
      mode: mode,
      battery: battery,
      temp: temp,
      wifi: wifi,
      isCharging: isCharging,
      isFullyCharged: isFullyCharged,
    );
  }
}
