
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/update_checker/application/update_notifier.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateNotificationBanner extends ConsumerWidget {
  const UpdateNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateUrl = ref.watch(updateAvailableProvider);

    if (updateUrl == null) {
      return const SizedBox.shrink(); // No update, no banner
    }

    return Material(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 16),
            const Expanded(
              child: Text('A new version is available!'),
            ),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(updateUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
  }
}
