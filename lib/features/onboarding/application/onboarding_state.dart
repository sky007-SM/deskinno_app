
import 'package:flutter/foundation.dart';

enum OnboardingPhase {
  booting,
  transitioningToScan,
  scanIdle,
  requestingPermissions,
  scanning,
}

@immutable
class OnboardingState {
  final OnboardingPhase phase;

  const OnboardingState({
    this.phase = OnboardingPhase.booting,
  });

  OnboardingState copyWith({
    OnboardingPhase? phase,
  }) {
    return OnboardingState(
      phase: phase ?? this.phase,
    );
  }
}
