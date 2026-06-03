import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/features/update_checker/application/update_notifier.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final updateServiceProvider = Provider((ref) => UpdateService(ref));

class UpdateService {
  final Ref _ref;
  UpdateService(this._ref);

  static const String _githubRepo = 'sky007-SM/INNO_BOT_APP';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_githubRepo/releases/latest';

  Future<void> checkForUpdate() async {
    try {
      final latestRelease = await _getLatestRelease();
      final currentVersion = await _getCurrentVersion();

      final latestVersion = latestRelease['tag_name'].toString().replaceAll(
        'v',
        '',
      );
      final currentVersionSanitized = currentVersion.split('+').first;

      if (_isNewerVersion(latestVersion, currentVersionSanitized)) {
        _ref
            .read(updateAvailableProvider.notifier)
            .setUpdate(latestRelease['html_url']);
      }
    } catch (e) {
      // Fail silently and log the error for debugging.
      debugPrint('Update check failed: $e');
    }
  }

  Future<Map<String, dynamic>> _getLatestRelease() async {
    final response = await http.get(Uri.parse(_githubApiUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to load release info from GitHub API. Status code: ${response.statusCode}',
      );
    }
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool _isNewerVersion(String latestVersion, String currentVersion) {
    final latestParts = latestVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (var i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) {
        return true; // e.g., 1.0.1 vs 1.0
      }
      if (latestParts[i] > currentParts[i]) {
        return true;
      }
      if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    return false;
  }
}
