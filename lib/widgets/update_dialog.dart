import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_version_info.dart';

class UpdateDialog extends StatelessWidget {
  final AppVersionInfo versionInfo;

  const UpdateDialog({super.key, required this.versionInfo});

  @override
  Widget build(BuildContext context) {
    bool isForceUpdate =
        versionInfo.isForceUpdate || versionInfo.isCriticalUpdate;

    return PopScope(
      canPop: !isForceUpdate, // Prevent back button if force update
      child: AlertDialog(
        title: Text(
          isForceUpdate ? 'Update Required' : 'Update Available',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Text(
              versionInfo.updateMessage ??
                  'A new version of DiscountBuddy is available. Please update to continue using the application with new features and improvements.',
            ),
            const SizedBox(height: 10),
            Text(
              'Latest Version: ${versionInfo.latestVersion ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ElevatedButton(
            onPressed: () async {
              if (versionInfo.storeUrl != null) {
                final url = Uri.parse(versionInfo.storeUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, AppVersionInfo versionInfo) {
    showDialog(
      context: context,
      barrierDismissible:
          !(versionInfo.isForceUpdate || versionInfo.isCriticalUpdate),
      builder: (context) => UpdateDialog(versionInfo: versionInfo),
    );
  }
}
