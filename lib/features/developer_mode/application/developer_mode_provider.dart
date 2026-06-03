
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to track the developer mode state
final developerModeEnabledProvider = StateProvider<bool>((ref) => false);

// Provider to manage the simulation state
final simulationProvider = StateNotifierProvider<SimulationNotifier, bool>((ref) => SimulationNotifier());

class SimulationNotifier extends StateNotifier<bool> {
  SimulationNotifier() : super(false);

  void startSimulation() {
    state = true;
  }

  void stopSimulation() {
    state = false;
  }
}
