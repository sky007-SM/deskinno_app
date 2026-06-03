import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Declare the Notifier class that holds the business logic
class SimulationModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // This sets your initial state
  }

  // Add helper methods to cleanly mutate state from the UI
  void toggle() => state = !state;
  void setMode(bool value) => state = value;
}

// 2. Expose the notifier to your application using a NotifierProvider
final simulationModeProvider = NotifierProvider<SimulationModeNotifier, bool>(() {
  return SimulationModeNotifier();
});
