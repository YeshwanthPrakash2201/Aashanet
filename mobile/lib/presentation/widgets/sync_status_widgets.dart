import 'package:flutter/material.dart';

import '../../application/app_services.dart';
import '../../application/sync_service.dart';
import '../../domain/record_status.dart';
import '../../infrastructure/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

// ============================================================
// ONLINE / OFFLINE BADGE (app bar)
// ============================================================

/// Shows Online / Offline / Syncing for the current user's services.
class ConnectionStatusBadge extends StatelessWidget {
  const ConnectionStatusBadge({
    super.key,
    required this.services,
    this.onDark = false,
  });

  final AppServices services;

  /// Glass style for use on the dark hero header.
  final bool onDark;

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
                ? (Icons.sync_rounded, l10n.syncing, AppColors.info)
                : online
                ? (Icons.cloud_done_rounded, l10n.online, AppColors.success)
                : (Icons.cloud_off_rounded, l10n.offline, AppColors.idle);

            final dotColor = onDark
                ? (syncing
                      ? const Color(0xFF8FC0FF)
                      : online
                      ? const Color(0xFF6EE7A8)
                      : Colors.white54)
                : color;

            // Tapping re-checks the server at once (and syncing starts
            // by itself if it is reachable), instead of waiting for the
            // next automatic check.
            return Semantics(
              label: label,
              liveRegion: true,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: services.connectivity.checkNow,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: onDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: onDark
                            ? Colors.white.withValues(alpha: 0.22)
                            : color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusDot(color: dotColor, pulsing: syncing),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Row(
                            key: ValueKey(label),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: onDark ? Colors.white : color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  color: onDark ? Colors.white : color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_StatusDot old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.pulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulsing && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!widget.pulsing) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
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
            TextButton(onPressed: onLogInAgain, child: Text(l10n.logInAgain)),
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

/// Colour that represents a record's sync state (used for the list's
/// accent rail and the sync chip).
Color syncColorFor(HealthRecord record) => switch (record.syncStatus) {
  SyncStatus.synced => AppColors.success,
  SyncStatus.uploading => AppColors.info,
  SyncStatus.syncFailed => AppColors.warning,
  SyncStatus.conflict => AppColors.danger,
  _ => AppColors.idle,
};

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

    final syncIcon = switch (record.syncStatus) {
      SyncStatus.synced => Icons.cloud_done_rounded,
      SyncStatus.uploading => Icons.cloud_upload_rounded,
      SyncStatus.syncFailed => Icons.sync_problem_rounded,
      SyncStatus.conflict => Icons.warning_amber_rounded,
      _ => online ? Icons.schedule_rounded : Icons.cloud_off_rounded,
    };

    final (aiIcon, aiColor) = record.recordStatus == RecordStatus.confirmed
        ? (Icons.verified_rounded, AppColors.success)
        : switch (record.aiStatus) {
            AiStatus.completed => (Icons.rate_review_rounded, AppColors.teal),
            AiStatus.failed => (Icons.edit_note_rounded, AppColors.warning),
            _ => (Icons.hourglass_empty_rounded, AppColors.idle),
          };

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _StatusPill(
          icon: syncIcon,
          color: syncColorFor(record),
          label: syncStatusLabel(l10n, record, online: online),
        ),
        _StatusPill(
          icon: aiIcon,
          color: aiColor,
          label: aiStatusLabel(l10n, record),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Color.lerp(color, Colors.black, 0.15),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
