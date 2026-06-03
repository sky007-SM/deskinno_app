
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/ble_connectivity/application/ble_provider.dart';
import 'package:myapp/features/ble_connectivity/domain/ble_device.dart';
import 'package:myapp/features/developer_mode/application/developer_mode_provider.dart';
import 'package:myapp/features/onboarding/application/onboarding_state.dart';
import 'package:myapp/features/robot_face/robot_face_component.dart';
import 'package:myapp/features/root_gate/presentation/root_gate.dart';
import 'package:myapp/services/permission_service.dart';

// Onboarding State Notifier
final onboardingStateProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void completeBooting() => state = state.copyWith(phase: OnboardingPhase.transitioningToScan);
  void completeTransition() => state = state.copyWith(phase: OnboardingPhase.scanIdle);
  void requestPermissions() => state = state.copyWith(phase: OnboardingPhase.requestingPermissions);
  void startScanning() => state = state.copyWith(phase: OnboardingPhase.scanning);
}


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with TickerProviderStateMixin {
  late AnimationController _bootController, _transitionController;
  late Animation<double> _bootAnimation;
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _bootController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
    _bootAnimation = CurvedAnimation(parent: _bootController, curve: Curves.easeInOut);
    _transitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _bootController.addStatusListener((status) {
      if (status == AnimationStatus.completed) ref.read(onboardingStateProvider.notifier).completeBooting();
    });
    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) ref.read(onboardingStateProvider.notifier).completeTransition();
    });
  }

  @override
  void dispose() {
    _bootController.dispose();
    _transitionController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    _tapCount++;
    _tapTimer?.cancel();
    if (_tapCount == 1) {
        _tapTimer = Timer(const Duration(seconds: 3), () => _tapCount = 0);
    }
    if (_tapCount >= 7) {
      ref.read(developerModeEnabledProvider.notifier).state = true;
      _tapCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OnboardingState>(onboardingStateProvider, (prev, next) {
      if (next.phase == OnboardingPhase.transitioningToScan && prev?.phase == OnboardingPhase.booting) {
        _transitionController.forward();
      }
    });

    final onboardingState = ref.watch(onboardingStateProvider);
    final isDeveloperMode = ref.watch(developerModeEnabledProvider);
    final bool isScanningPhase = [OnboardingPhase.scanIdle, OnboardingPhase.requestingPermissions, OnboardingPhase.scanning].contains(onboardingState.phase);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bootAnimation, _transitionController]),
        builder: (context, child) {
          final faceAlignment = Alignment.lerp(Alignment.center, const Alignment(0.0, -0.7), _transitionController.value)!;
          final faceScale = (1 - (_transitionController.value * 0.5));

          return Stack(
            children: [
              GestureDetector(
                onTap: _handleTap,
                child: Align(
                  alignment: faceAlignment,
                  child: Transform.scale(
                    scale: faceScale,
                    child: const RiverpodRobotFace(),
                  ),
                ),
              ),
              if (isScanningPhase) Align(alignment: Alignment.center, child: _buildScanningUI()),
              if (isDeveloperMode) _buildDevModeButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScanningUI() {
    final onboardingState = ref.watch(onboardingStateProvider);
    final onboardingNotifier = ref.read(onboardingStateProvider.notifier);
    final bleNotifier = ref.read(bleProvider.notifier);
    final bleState = ref.watch(bleProvider);
    final PermissionService permService = PermissionService();
    final screenSize = MediaQuery.of(context).size;

    final bool isScanning = onboardingState.phase == OnboardingPhase.scanning;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: screenSize.width * 0.85,
      height: isScanning ? screenSize.height * 0.5 : 60,
      decoration: BoxDecoration(color: Colors.black.withAlpha(77), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.cyan.withAlpha(128))),
      child: isScanning
          ? _buildDeviceList(bleState.discoveredDevices)
          : Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                onPressed: () async {
                  onboardingNotifier.requestPermissions();
                  bool granted = await permService.requestPermissions();
                  if (granted) {
                    onboardingNotifier.startScanning();
                    bleNotifier.startScan();
                  } else {
                    onboardingNotifier.completeTransition();
                     if (mounted) permService.showPermissionDialog(context);
                  }
                },
                child: const Text('Scan for Devices'),
              ),
            ),
    );
  }

  Widget _buildDeviceList(List<BleDevice> devices) {
    if (devices.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 24), Text('Searching for TableBot...')]));
    }

    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return ListTile(
          title: Text(device.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(device.device.remoteId.toString(), style: TextStyle(color: Colors.grey[400])),
          trailing: const Icon(Icons.chevron_right, color: Colors.cyanAccent),
          onTap: () {
            ref.read(bleProvider.notifier).connect(device.device);
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const RootGate()));
          },
        );
      },
    );
  }
  
  Widget _buildDevModeButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 48.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)
          ),
          onPressed: () {
            ref.read(simulationProvider.notifier).startSimulation();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const RootGate()));
          },
          child: const Text('Launch Mock Mode (Simulated Hardware)'),
        ),
      ),
    );
  }
}
