import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpdateAvailableNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // This sets your initial state
  }

  void setUpdate(String? version) => state = version;
}

final updateAvailableProvider = NotifierProvider<UpdateAvailableNotifier, String?>(() {
  return UpdateAvailableNotifier();
});
