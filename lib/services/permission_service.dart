
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

/// A service to handle required permissions for the application.
///
/// This service is responsible for requesting necessary permissions like
/// Bluetooth and location. If permissions are denied, it provides a way
/// to guide the user to the application settings to manually enable them.
class PermissionService {
  /// Requests Bluetooth and location permissions.
  ///
  /// This method requests multiple permissions at once.
  /// Returns `true` if all permissions are granted, `false` otherwise.
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses[Permission.bluetoothScan]!.isGranted &&
           statuses[Permission.bluetoothConnect]!.isGranted &&
           statuses[Permission.location]!.isGranted;
  }

  /// Shows a dialog explaining the need for permissions and provides a
  /// button to open the app settings.
  ///
  /// This dialog is non-dismissible and should be shown when permissions
  /// are permanently denied.
  void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
              'This app needs Bluetooth and location permissions to function correctly. '
              'Please enable them in the app settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Phone Settings'),
              onPressed: () {
                AppSettings.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
}
