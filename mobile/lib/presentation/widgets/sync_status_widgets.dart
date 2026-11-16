import 'package:flutter/material.dart';

import '../../application/app_services.dart';
import '../../application/sync_service.dart';
import '../../domain/record_status.dart';
import '../../infrastructure/database/app_database.dart';
import '../../l10n/app_localizations.dart';

// ============================================================
// ONLINE / OFFLINE BADGE (app bar)
// ============================================================

/// Shows Online / Offline / Syncing for the current user's services.
class ConnectionStatusBadge extends StatelessWidget {
  const ConnectionStatusBadge({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<bool>(
      valueListenable: services.connectivity.isOnline,
      builder: (context, online, _) {
        return ValueListenableBuilder<SyncActivity>(
          valueListenable: services.sync.activity,
          builder: (context, activity, _) {
            final syncing = online && activity == SyncActivity.syncing;

            final (icon, label, color) = syncing
                ? (Icons.sync, l10n.syncing, Colors.blue.shade700)
                : online
                    ? (Icons.cloud_done, l10n.online, Colors.green.shade700)
                    : (Icons.cloud_off, l10n.offline, Colors.grey.shade700);

            return Semantics(
              label: label,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Chip(
                  avatar: Icon(icon, size: 18, color: color),
                  label: Text(label),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// LOGIN-EXPIRED BANNER
// ============================================================

/// Appears when the sync engine needs a fresh login. Records keep
/// waiting on the phone until then.
class LoginRequiredBanner extends StatelessWidget {
  const LoginRequiredBanner({
    super.key,
    required this.services,
    required this.onLogInAgain,
  });

  final AppServices services;
  final VoidCallback onLogInAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<SyncActivity>(
      valueListenable: services.sync.activity,
      builder: (context, activity, _) {
        if (activity != SyncActivity.loginRequired) {
          return const SizedBox.shrink();
        }

        return MaterialBanner(
          leading: const Icon(Icons.lock_clock),
          content: Text(l10n.loginToSync),
          actions: [
            TextButton(
              onPressed: onLogInAgain,
              child: Text(l10n.logInAgain),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// PER-RECORD STATUS CHIPS
// ============================================================

String syncStatusLabel(
  AppLocalizations l10n,
  HealthRecord record, {
  required bool online,
}) {
  switch (record.syncStatus) {
    case SyncStatus.uploading:
      return l10n.statusUploading;
    case SyncStatus.synced:
      return l10n.statusSynced;
    case SyncStatus.syncFailed:
      return l10n.statusSyncFailed;
    case SyncStatus.conflict:
      return l10n.statusConflict;
    default:
      // Waiting to be sent: "Saved offline" while there is no
      // connection, "Pending sync" while the queue is being worked on.
      return online ? l10n.statusPendingSync : l10n.statusSavedOffline;
  }
}

String aiStatusLabel(AppLocalizations l10n, HealthRecord record) {
  if (record.recordStatus == RecordStatus.confirmed) {
    return l10n.statusConfirmed;
  }

  switch (record.aiStatus) {
    case AiStatus.completed:
      return l10n.aiCompleted;
    case AiStatus.failed:
      return l10n.aiFailed;
    default:
      return l10n.aiPending;
  }
}

class RecordStatusChips extends StatelessWidget {
  const RecordStatusChips({
    super.key,
    required this.record,
    required this.online,
  });

  final HealthRecord record;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (syncIcon, syncColor) = switch (record.syncStatus) {
      SyncStatus.synced => (Icons.cloud_done, Colors.green.shade700),
      SyncStatus.uploading => (Icons.cloud_upload, Colors.blue.shade700),
      SyncStatus.syncFailed => (Icons.sync_problem, Colors.orange.shade800),
      SyncStatus.conflict => (Icons.warning_amber, Colors.red.shade700),
      _ => (
          online ? Icons.schedule : Icons.cloud_off,
          Colors.grey.shade700,
        ),
    };

    final (aiIcon, aiColor) = record.recordStatus == RecordStatus.confirmed
        ? (Icons.verified, Colors.green.shade700)
        : switch (record.aiStatus) {
            AiStatus.completed => (Icons.rate_review, Colors.teal.shade700),
            AiStatus.failed => (Icons.edit_note, Colors.orange.shade800),
            _ => (Icons.hourglass_empty, Colors.grey.shade700),
          };

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _chip(syncIcon, syncColor,
            syncStatusLabel(l10n, record, online: online)),
        _chip(aiIcon, aiColor, aiStatusLabel(l10n, record)),
      ],
    );
  }

  Widget _chip(IconData icon, Color color, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}
