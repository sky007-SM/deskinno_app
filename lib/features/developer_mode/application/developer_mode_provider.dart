import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider to manage the developer mode state.
class DeveloperModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Initial state is disabled
  }

  /// Toggles the developer mode state.
  void toggle() {
    state = !state;
  }
}

final developerModeProvider = NotifierProvider<DeveloperModeNotifier, bool>(() {
  return DeveloperModeNotifier();
});
