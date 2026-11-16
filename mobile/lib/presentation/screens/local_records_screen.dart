import 'dart:io';

import 'package:flutter/material.dart';

import '../../application/app_services.dart';
import '../../domain/record_status.dart';
import '../../domain/repositories/health_record_local_repository.dart';
import '../../infrastructure/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/design.dart';
import '../widgets/sync_status_widgets.dart';

/// Every record saved on this phone by the logged-in worker, with its
/// sync and AI status. Updates live while syncing runs in the
/// background, and stays fully usable offline.
class LocalRecordsScreen extends StatelessWidget {
  const LocalRecordsScreen({
    super.key,
    required this.services,
    required this.onReview,
  });

  final AppServices services;

  /// Opens the review screen for a record whose AI step has finished.
  final void Function(BuildContext context, HealthRecord record) onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.localHealthRecords),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: services.connectivity.isOnline,
            builder: (context, online, _) => IconButton(
              tooltip: l10n.syncNow,
              icon: const Icon(Icons.sync),
              onPressed: online ? services.sync.syncAll : null,
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: services.connectivity.isOnline,
        builder: (context, online, _) {
          return StreamBuilder<List<HealthRecord>>(
            stream: services.records.watchRecordsForOwner(services.username),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '${l10n.couldNotLoadRecords}:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final records = snapshot.data!;

              if (records.isEmpty) {
                return EmptyState(
                  icon: Icons.folder_open_rounded,
                  message: l10n.noLocalHealthRecords,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                itemCount: records.length,
                itemBuilder: (context, index) => ResponsiveCenter(
                  maxWidth: 820,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FadeSlideIn(
                    delay: Duration(milliseconds: 40 * (index < 8 ? index : 8)),
                    child: _RecordTile(
                      record: records[index],
                      online: online,
                      onTap: () => _open(context, records[index]),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _open(BuildContext context, HealthRecord record) {
    if (record.syncStatus == SyncStatus.conflict) {
      showDialog<void>(
        context: context,
        builder: (_) => _ConflictDialog(services: services, record: record),
      );
      return;
    }

    final reviewable = record.recordStatus == RecordStatus.draft &&
        record.serverRecordId != null &&
        (record.aiStatus == AiStatus.completed ||
            record.aiStatus == AiStatus.failed);

    if (reviewable) {
      onReview(context, record);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => _DetailsDialog(record: record),
    );
  }
}

// ============================================================
// LIST TILE
// ============================================================

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.online,
    required this.onTap,
  });

  final HealthRecord record;
  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final confirmed =
        HealthRecordLocalRepository.decodeJson(record.confirmedData);
    final suggested =
        HealthRecordLocalRepository.decodeJson(record.aiSuggestedData);
    final name = confirmed?['patient_name'] ?? suggested?['patient_name'];
    final accent = syncColorFor(record);
    final isVoice = record.audioPath != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: onTap,
        semanticLabel: name?.toString() ?? record.rawInput,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status rail: the record's sync state at a glance.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 5,
                    color: accent,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isVoice
                                  ? AppColors.marigoldMist
                                  : AppColors.tealMist,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Icon(
                              isVoice
                                  ? Icons.mic_rounded
                                  : Icons.notes_rounded,
                              color: isVoice
                                  ? AppColors.saffron
                                  : AppColors.teal,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name?.toString() ?? record.rawInput,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: AppColors.inkMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(record.createdAt),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                RecordStatusChips(
                                  record: record,
                                  online: online,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');

  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _describe(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) {
    return '–';
  }

  final symptoms = data['symptoms'];

  return [
    if (data['patient_name'] != null) '${data['patient_name']}',
    if (data['age'] != null) '${data['age']}',
    if (symptoms is List && symptoms.isNotEmpty) symptoms.join(', '),
    if (data['duration'] != null) '${data['duration']}',
  ].join(' · ');
}

// ============================================================
// DETAILS DIALOG
// ============================================================

class _DetailsDialog extends StatelessWidget {
  const _DetailsDialog({required this.record});

  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final confirmed =
        HealthRecordLocalRepository.decodeJson(record.confirmedData);

    Widget section(String title, String? body) {
      if (body == null || body.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text(l10n.recordDetails),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecordStatusChips(record: record, online: true),
            const SizedBox(height: 12),
            section(l10n.createdLabel, _formatDate(record.createdAt)),
            section(l10n.confirmedDetails,
                confirmed == null ? null : _describe(confirmed)),
            section(l10n.transcriptLabel, record.aiTranscript),
            section(l10n.translationLabel, record.aiTranslation),
            if (record.audioPath == null) section('', record.rawInput),
            if (record.audioPath != null &&
                File(record.audioPath!).existsSync())
              Row(
                children: [
                  const Icon(Icons.audio_file, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(l10n.audioKeptOnPhone)),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

// ============================================================
// CONFLICT DIALOG
// ============================================================

/// Shows both versions side by side. Nothing is overwritten until the
/// worker chooses; choosing the server version keeps the worker's own
/// version stored on the phone.
class _ConflictDialog extends StatelessWidget {
  const _ConflictDialog({required this.services, required this.record});

  final AppServices services;
  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.conflictTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.conflictBody),
            const SizedBox(height: 16),
            Text(l10n.yourVersion,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_describe(
                HealthRecordLocalRepository.decodeJson(record.confirmedData))),
            const SizedBox(height: 12),
            Text(l10n.serverVersion,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_describe(HealthRecordLocalRepository.decodeJson(
                record.conflictServerData))),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.later),
        ),
        FilledButton(
          onPressed: () async {
            await services.records.resolveConflictWithServerVersion(record.id);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text(l10n.useServerVersion),
        ),
      ],
    );
  }
}
