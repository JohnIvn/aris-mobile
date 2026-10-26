import 'package:flutter/material.dart';

import '../stores/update_stores.dart';
import '../theme/theme_scope.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateStore store;

  const UpdateDialog({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final status = store.status;
        final busy =
            status == UpdateStatus.downloading ||
            status == UpdateStatus.installing;

        return PopScope(
          canPop: !busy,
          child: AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Update available',
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version ${store.latestVersion} is ready '
                  '(you have ${store.currentVersion}).',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                if (status == UpdateStatus.available &&
                    (store.notes?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: SingleChildScrollView(
                      child: Text(
                        store.notes!,
                        style: TextStyle(color: colors.text, fontSize: 13),
                      ),
                    ),
                  ),
                ],
                if (status == UpdateStatus.downloading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: store.progress == 0 ? null : store.progress / 100,
                    color: colors.accentActive,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Downloading… ${store.progress}%',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                if (status == UpdateStatus.installing) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Follow the installer prompt to finish.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                if (status == UpdateStatus.error) ...[
                  const SizedBox(height: 12),
                  Text(
                    store.error ?? 'Update failed.',
                    style: TextStyle(color: colors.error, fontSize: 13),
                  ),
                ],
              ],
            ),
            actions: busy
                ? null
                : [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Later',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: store.install,
                      child: Text(
                        status == UpdateStatus.error ? 'Retry' : 'Update',
                        style: TextStyle(
                          color: colors.accentActive,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
          ),
        );
      },
    );
  }
}
