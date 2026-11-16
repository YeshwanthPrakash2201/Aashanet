// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HealthRecordsTable extends HealthRecords
    with TableInfo<$HealthRecordsTable, HealthRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRecordIdMeta = const VerificationMeta(
    'clientRecordId',
  );
  @override
  late final GeneratedColumn<String> clientRecordId = GeneratedColumn<String>(
    'client_record_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerUsernameMeta = const VerificationMeta(
    'ownerUsername',
  );
  @override
  late final GeneratedColumn<String> ownerUsername = GeneratedColumn<String>(
    'owner_username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverRecordIdMeta = const VerificationMeta(
    'serverRecordId',
  );
  @override
  late final GeneratedColumn<String> serverRecordId = GeneratedColumn<String>(
    'server_record_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawInputMeta = const VerificationMeta(
    'rawInput',
  );
  @override
  late final GeneratedColumn<String> rawInput = GeneratedColumn<String>(
    'raw_input',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputLanguageMeta = const VerificationMeta(
    'inputLanguage',
  );
  @override
  late final GeneratedColumn<String> inputLanguage = GeneratedColumn<String>(
    'input_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiStatusMeta = const VerificationMeta(
    'aiStatus',
  );
  @override
  late final GeneratedColumn<String> aiStatus = GeneratedColumn<String>(
    'ai_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(AiStatus.pending),
  );
  static const VerificationMeta _aiTranscriptMeta = const VerificationMeta(
    'aiTranscript',
  );
  @override
  late final GeneratedColumn<String> aiTranscript = GeneratedColumn<String>(
    'ai_transcript',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiTranslationMeta = const VerificationMeta(
    'aiTranslation',
  );
  @override
  late final GeneratedColumn<String> aiTranslation = GeneratedColumn<String>(
    'ai_translation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiSuggestedDataMeta = const VerificationMeta(
    'aiSuggestedData',
  );
  @override
  late final GeneratedColumn<String> aiSuggestedData = GeneratedColumn<String>(
    'ai_suggested_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordStatusMeta = const VerificationMeta(
    'recordStatus',
  );
  @override
  late final GeneratedColumn<String> recordStatus = GeneratedColumn<String>(
    'record_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(RecordStatus.draft),
  );
  static const VerificationMeta _confirmedDataMeta = const VerificationMeta(
    'confirmedData',
  );
  @override
  late final GeneratedColumn<String> confirmedData = GeneratedColumn<String>(
    'confirmed_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncStatus.pendingSync),
  );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextSyncAtMeta = const VerificationMeta(
    'nextSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextSyncAt = GeneratedColumn<DateTime>(
    'next_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conflictServerDataMeta =
      const VerificationMeta('conflictServerData');
  @override
  late final GeneratedColumn<String> conflictServerData =
      GeneratedColumn<String>(
        'conflict_server_data',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _conflictLocalDataMeta = const VerificationMeta(
    'conflictLocalData',
  );
  @override
  late final GeneratedColumn<String> conflictLocalData =
      GeneratedColumn<String>(
        'conflict_local_data',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientRecordId,
    ownerUsername,
    serverRecordId,
    workerId,
    rawInput,
    inputLanguage,
    audioPath,
    aiStatus,
    aiTranscript,
    aiTranslation,
    aiSuggestedData,
    recordStatus,
    confirmedData,
    syncStatus,
    syncAttempts,
    nextSyncAt,
    lastSyncError,
    serverVersion,
    conflictServerData,
    conflictLocalData,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_record_id')) {
      context.handle(
        _clientRecordIdMeta,
        clientRecordId.isAcceptableOrUnknown(
          data['client_record_id']!,
          _clientRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('owner_username')) {
      context.handle(
        _ownerUsernameMeta,
        ownerUsername.isAcceptableOrUnknown(
          data['owner_username']!,
          _ownerUsernameMeta,
        ),
      );
    }
    if (data.containsKey('server_record_id')) {
      context.handle(
        _serverRecordIdMeta,
        serverRecordId.isAcceptableOrUnknown(
          data['server_record_id']!,
          _serverRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    }
    if (data.containsKey('raw_input')) {
      context.handle(
        _rawInputMeta,
        rawInput.isAcceptableOrUnknown(data['raw_input']!, _rawInputMeta),
      );
    } else if (isInserting) {
      context.missing(_rawInputMeta);
    }
    if (data.containsKey('input_language')) {
      context.handle(
        _inputLanguageMeta,
        inputLanguage.isAcceptableOrUnknown(
          data['input_language']!,
          _inputLanguageMeta,
        ),
      );
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('ai_status')) {
      context.handle(
        _aiStatusMeta,
        aiStatus.isAcceptableOrUnknown(data['ai_status']!, _aiStatusMeta),
      );
    }
    if (data.containsKey('ai_transcript')) {
      context.handle(
        _aiTranscriptMeta,
        aiTranscript.isAcceptableOrUnknown(
          data['ai_transcript']!,
          _aiTranscriptMeta,
        ),
      );
    }
    if (data.containsKey('ai_translation')) {
      context.handle(
        _aiTranslationMeta,
        aiTranslation.isAcceptableOrUnknown(
          data['ai_translation']!,
          _aiTranslationMeta,
        ),
      );
    }
    if (data.containsKey('ai_suggested_data')) {
      context.handle(
        _aiSuggestedDataMeta,
        aiSuggestedData.isAcceptableOrUnknown(
          data['ai_suggested_data']!,
          _aiSuggestedDataMeta,
        ),
      );
    }
    if (data.containsKey('record_status')) {
      context.handle(
        _recordStatusMeta,
        recordStatus.isAcceptableOrUnknown(
          data['record_status']!,
          _recordStatusMeta,
        ),
      );
    }
    if (data.containsKey('confirmed_data')) {
      context.handle(
        _confirmedDataMeta,
        confirmedData.isAcceptableOrUnknown(
          data['confirmed_data']!,
          _confirmedDataMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('next_sync_at')) {
      context.handle(
        _nextSyncAtMeta,
        nextSyncAt.isAcceptableOrUnknown(
          data['next_sync_at']!,
          _nextSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('conflict_server_data')) {
      context.handle(
        _conflictServerDataMeta,
        conflictServerData.isAcceptableOrUnknown(
          data['conflict_server_data']!,
          _conflictServerDataMeta,
        ),
      );
    }
    if (data.containsKey('conflict_local_data')) {
      context.handle(
        _conflictLocalDataMeta,
        conflictLocalData.isAcceptableOrUnknown(
          data['conflict_local_data']!,
          _conflictLocalDataMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_record_id'],
      ),
      ownerUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_username'],
      ),
      serverRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_record_id'],
      ),
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      ),
      rawInput: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_input'],
      )!,
      inputLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_language'],
      ),
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      aiStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_status'],
      )!,
      aiTranscript: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_transcript'],
      ),
      aiTranslation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_translation'],
      ),
      aiSuggestedData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_suggested_data'],
      ),
      recordStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_status'],
      )!,
      confirmedData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_data'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      nextSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_sync_at'],
      ),
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      conflictServerData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_server_data'],
      ),
      conflictLocalData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_local_data'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HealthRecordsTable createAlias(String alias) {
    return $HealthRecordsTable(attachedDatabase, alias);
  }
}

class HealthRecord extends DataClass implements Insertable<HealthRecord> {
  final String id;
  final String? clientRecordId;
  final String? ownerUsername;
  final String? serverRecordId;
  final String? workerId;
  final String rawInput;
  final String? inputLanguage;
  final String? audioPath;
  final String aiStatus;
  final String? aiTranscript;
  final String? aiTranslation;
  final String? aiSuggestedData;
  final String recordStatus;
  final String? confirmedData;
  final String syncStatus;
  final int syncAttempts;
  final DateTime? nextSyncAt;
  final String? lastSyncError;
  final int? serverVersion;
  final String? conflictServerData;
  final String? conflictLocalData;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HealthRecord({
    required this.id,
    this.clientRecordId,
    this.ownerUsername,
    this.serverRecordId,
    this.workerId,
    required this.rawInput,
    this.inputLanguage,
    this.audioPath,
    required this.aiStatus,
    this.aiTranscript,
    this.aiTranslation,
    this.aiSuggestedData,
    required this.recordStatus,
    this.confirmedData,
    required this.syncStatus,
    required this.syncAttempts,
    this.nextSyncAt,
    this.lastSyncError,
    this.serverVersion,
    this.conflictServerData,
    this.conflictLocalData,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || clientRecordId != null) {
      map['client_record_id'] = Variable<String>(clientRecordId);
    }
    if (!nullToAbsent || ownerUsername != null) {
      map['owner_username'] = Variable<String>(ownerUsername);
    }
    if (!nullToAbsent || serverRecordId != null) {
      map['server_record_id'] = Variable<String>(serverRecordId);
    }
    if (!nullToAbsent || workerId != null) {
      map['worker_id'] = Variable<String>(workerId);
    }
    map['raw_input'] = Variable<String>(rawInput);
    if (!nullToAbsent || inputLanguage != null) {
      map['input_language'] = Variable<String>(inputLanguage);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['ai_status'] = Variable<String>(aiStatus);
    if (!nullToAbsent || aiTranscript != null) {
      map['ai_transcript'] = Variable<String>(aiTranscript);
    }
    if (!nullToAbsent || aiTranslation != null) {
      map['ai_translation'] = Variable<String>(aiTranslation);
    }
    if (!nullToAbsent || aiSuggestedData != null) {
      map['ai_suggested_data'] = Variable<String>(aiSuggestedData);
    }
    map['record_status'] = Variable<String>(recordStatus);
    if (!nullToAbsent || confirmedData != null) {
      map['confirmed_data'] = Variable<String>(confirmedData);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || nextSyncAt != null) {
      map['next_sync_at'] = Variable<DateTime>(nextSyncAt);
    }
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || conflictServerData != null) {
      map['conflict_server_data'] = Variable<String>(conflictServerData);
    }
    if (!nullToAbsent || conflictLocalData != null) {
      map['conflict_local_data'] = Variable<String>(conflictLocalData);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HealthRecordsCompanion toCompanion(bool nullToAbsent) {
    return HealthRecordsCompanion(
      id: Value(id),
      clientRecordId: clientRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientRecordId),
      ownerUsername: ownerUsername == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUsername),
      serverRecordId: serverRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverRecordId),
      workerId: workerId == null && nullToAbsent
          ? const Value.absent()
          : Value(workerId),
      rawInput: Value(rawInput),
      inputLanguage: inputLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(inputLanguage),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      aiStatus: Value(aiStatus),
      aiTranscript: aiTranscript == null && nullToAbsent
          ? const Value.absent()
          : Value(aiTranscript),
      aiTranslation: aiTranslation == null && nullToAbsent
          ? const Value.absent()
          : Value(aiTranslation),
      aiSuggestedData: aiSuggestedData == null && nullToAbsent
          ? const Value.absent()
          : Value(aiSuggestedData),
      recordStatus: Value(recordStatus),
      confirmedData: confirmedData == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedData),
      syncStatus: Value(syncStatus),
      syncAttempts: Value(syncAttempts),
      nextSyncAt: nextSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextSyncAt),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      conflictServerData: conflictServerData == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictServerData),
      conflictLocalData: conflictLocalData == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictLocalData),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HealthRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthRecord(
      id: serializer.fromJson<String>(json['id']),
      clientRecordId: serializer.fromJson<String?>(json['clientRecordId']),
      ownerUsername: serializer.fromJson<String?>(json['ownerUsername']),
      serverRecordId: serializer.fromJson<String?>(json['serverRecordId']),
      workerId: serializer.fromJson<String?>(json['workerId']),
      rawInput: serializer.fromJson<String>(json['rawInput']),
      inputLanguage: serializer.fromJson<String?>(json['inputLanguage']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      aiStatus: serializer.fromJson<String>(json['aiStatus']),
      aiTranscript: serializer.fromJson<String?>(json['aiTranscript']),
      aiTranslation: serializer.fromJson<String?>(json['aiTranslation']),
      aiSuggestedData: serializer.fromJson<String?>(json['aiSuggestedData']),
      recordStatus: serializer.fromJson<String>(json['recordStatus']),
      confirmedData: serializer.fromJson<String?>(json['confirmedData']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      nextSyncAt: serializer.fromJson<DateTime?>(json['nextSyncAt']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      conflictServerData: serializer.fromJson<String?>(
        json['conflictServerData'],
      ),
      conflictLocalData: serializer.fromJson<String?>(
        json['conflictLocalData'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientRecordId': serializer.toJson<String?>(clientRecordId),
      'ownerUsername': serializer.toJson<String?>(ownerUsername),
      'serverRecordId': serializer.toJson<String?>(serverRecordId),
      'workerId': serializer.toJson<String?>(workerId),
      'rawInput': serializer.toJson<String>(rawInput),
      'inputLanguage': serializer.toJson<String?>(inputLanguage),
      'audioPath': serializer.toJson<String?>(audioPath),
      'aiStatus': serializer.toJson<String>(aiStatus),
      'aiTranscript': serializer.toJson<String?>(aiTranscript),
      'aiTranslation': serializer.toJson<String?>(aiTranslation),
      'aiSuggestedData': serializer.toJson<String?>(aiSuggestedData),
      'recordStatus': serializer.toJson<String>(recordStatus),
      'confirmedData': serializer.toJson<String?>(confirmedData),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'nextSyncAt': serializer.toJson<DateTime?>(nextSyncAt),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'conflictServerData': serializer.toJson<String?>(conflictServerData),
      'conflictLocalData': serializer.toJson<String?>(conflictLocalData),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HealthRecord copyWith({
    String? id,
    Value<String?> clientRecordId = const Value.absent(),
    Value<String?> ownerUsername = const Value.absent(),
    Value<String?> serverRecordId = const Value.absent(),
    Value<String?> workerId = const Value.absent(),
    String? rawInput,
    Value<String?> inputLanguage = const Value.absent(),
    Value<String?> audioPath = const Value.absent(),
    String? aiStatus,
    Value<String?> aiTranscript = const Value.absent(),
    Value<String?> aiTranslation = const Value.absent(),
    Value<String?> aiSuggestedData = const Value.absent(),
    String? recordStatus,
    Value<String?> confirmedData = const Value.absent(),
    String? syncStatus,
    int? syncAttempts,
    Value<DateTime?> nextSyncAt = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<String?> conflictServerData = const Value.absent(),
    Value<String?> conflictLocalData = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HealthRecord(
    id: id ?? this.id,
    clientRecordId: clientRecordId.present
        ? clientRecordId.value
        : this.clientRecordId,
    ownerUsername: ownerUsername.present
        ? ownerUsername.value
        : this.ownerUsername,
    serverRecordId: serverRecordId.present
        ? serverRecordId.value
        : this.serverRecordId,
    workerId: workerId.present ? workerId.value : this.workerId,
    rawInput: rawInput ?? this.rawInput,
    inputLanguage: inputLanguage.present
        ? inputLanguage.value
        : this.inputLanguage,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    aiStatus: aiStatus ?? this.aiStatus,
    aiTranscript: aiTranscript.present ? aiTranscript.value : this.aiTranscript,
    aiTranslation: aiTranslation.present
        ? aiTranslation.value
        : this.aiTranslation,
    aiSuggestedData: aiSuggestedData.present
        ? aiSuggestedData.value
        : this.aiSuggestedData,
    recordStatus: recordStatus ?? this.recordStatus,
    confirmedData: confirmedData.present
        ? confirmedData.value
        : this.confirmedData,
    syncStatus: syncStatus ?? this.syncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    nextSyncAt: nextSyncAt.present ? nextSyncAt.value : this.nextSyncAt,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    conflictServerData: conflictServerData.present
        ? conflictServerData.value
        : this.conflictServerData,
    conflictLocalData: conflictLocalData.present
        ? conflictLocalData.value
        : this.conflictLocalData,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HealthRecord copyWithCompanion(HealthRecordsCompanion data) {
    return HealthRecord(
      id: data.id.present ? data.id.value : this.id,
      clientRecordId: data.clientRecordId.present
          ? data.clientRecordId.value
          : this.clientRecordId,
      ownerUsername: data.ownerUsername.present
          ? data.ownerUsername.value
          : this.ownerUsername,
      serverRecordId: data.serverRecordId.present
          ? data.serverRecordId.value
          : this.serverRecordId,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      rawInput: data.rawInput.present ? data.rawInput.value : this.rawInput,
      inputLanguage: data.inputLanguage.present
          ? data.inputLanguage.value
          : this.inputLanguage,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      aiStatus: data.aiStatus.present ? data.aiStatus.value : this.aiStatus,
      aiTranscript: data.aiTranscript.present
          ? data.aiTranscript.value
          : this.aiTranscript,
      aiTranslation: data.aiTranslation.present
          ? data.aiTranslation.value
          : this.aiTranslation,
      aiSuggestedData: data.aiSuggestedData.present
          ? data.aiSuggestedData.value
          : this.aiSuggestedData,
      recordStatus: data.recordStatus.present
          ? data.recordStatus.value
          : this.recordStatus,
      confirmedData: data.confirmedData.present
          ? data.confirmedData.value
          : this.confirmedData,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      nextSyncAt: data.nextSyncAt.present
          ? data.nextSyncAt.value
          : this.nextSyncAt,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      conflictServerData: data.conflictServerData.present
          ? data.conflictServerData.value
          : this.conflictServerData,
      conflictLocalData: data.conflictLocalData.present
          ? data.conflictLocalData.value
          : this.conflictLocalData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthRecord(')
          ..write('id: $id, ')
          ..write('clientRecordId: $clientRecordId, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('serverRecordId: $serverRecordId, ')
          ..write('workerId: $workerId, ')
          ..write('rawInput: $rawInput, ')
          ..write('inputLanguage: $inputLanguage, ')
          ..write('audioPath: $audioPath, ')
          ..write('aiStatus: $aiStatus, ')
          ..write('aiTranscript: $aiTranscript, ')
          ..write('aiTranslation: $aiTranslation, ')
          ..write('aiSuggestedData: $aiSuggestedData, ')
          ..write('recordStatus: $recordStatus, ')
          ..write('confirmedData: $confirmedData, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('nextSyncAt: $nextSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('conflictServerData: $conflictServerData, ')
          ..write('conflictLocalData: $conflictLocalData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    clientRecordId,
    ownerUsername,
    serverRecordId,
    workerId,
    rawInput,
    inputLanguage,
    audioPath,
    aiStatus,
    aiTranscript,
    aiTranslation,
    aiSuggestedData,
    recordStatus,
    confirmedData,
    syncStatus,
    syncAttempts,
    nextSyncAt,
    lastSyncError,
    serverVersion,
    conflictServerData,
    conflictLocalData,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthRecord &&
          other.id == this.id &&
          other.clientRecordId == this.clientRecordId &&
          other.ownerUsername == this.ownerUsername &&
          other.serverRecordId == this.serverRecordId &&
          other.workerId == this.workerId &&
          other.rawInput == this.rawInput &&
          other.inputLanguage == this.inputLanguage &&
          other.audioPath == this.audioPath &&
          other.aiStatus == this.aiStatus &&
          other.aiTranscript == this.aiTranscript &&
          other.aiTranslation == this.aiTranslation &&
          other.aiSuggestedData == this.aiSuggestedData &&
          other.recordStatus == this.recordStatus &&
          other.confirmedData == this.confirmedData &&
          other.syncStatus == this.syncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.nextSyncAt == this.nextSyncAt &&
          other.lastSyncError == this.lastSyncError &&
          other.serverVersion == this.serverVersion &&
          other.conflictServerData == this.conflictServerData &&
          other.conflictLocalData == this.conflictLocalData &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HealthRecordsCompanion extends UpdateCompanion<HealthRecord> {
  final Value<String> id;
  final Value<String?> clientRecordId;
  final Value<String?> ownerUsername;
  final Value<String?> serverRecordId;
  final Value<String?> workerId;
  final Value<String> rawInput;
  final Value<String?> inputLanguage;
  final Value<String?> audioPath;
  final Value<String> aiStatus;
  final Value<String?> aiTranscript;
  final Value<String?> aiTranslation;
  final Value<String?> aiSuggestedData;
  final Value<String> recordStatus;
  final Value<String?> confirmedData;
  final Value<String> syncStatus;
  final Value<int> syncAttempts;
  final Value<DateTime?> nextSyncAt;
  final Value<String?> lastSyncError;
  final Value<int?> serverVersion;
  final Value<String?> conflictServerData;
  final Value<String?> conflictLocalData;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HealthRecordsCompanion({
    this.id = const Value.absent(),
    this.clientRecordId = const Value.absent(),
    this.ownerUsername = const Value.absent(),
    this.serverRecordId = const Value.absent(),
    this.workerId = const Value.absent(),
    this.rawInput = const Value.absent(),
    this.inputLanguage = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.aiStatus = const Value.absent(),
    this.aiTranscript = const Value.absent(),
    this.aiTranslation = const Value.absent(),
    this.aiSuggestedData = const Value.absent(),
    this.recordStatus = const Value.absent(),
    this.confirmedData = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.nextSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.conflictServerData = const Value.absent(),
    this.conflictLocalData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthRecordsCompanion.insert({
    required String id,
    this.clientRecordId = const Value.absent(),
    this.ownerUsername = const Value.absent(),
    this.serverRecordId = const Value.absent(),
    this.workerId = const Value.absent(),
    required String rawInput,
    this.inputLanguage = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.aiStatus = const Value.absent(),
    this.aiTranscript = const Value.absent(),
    this.aiTranslation = const Value.absent(),
    this.aiSuggestedData = const Value.absent(),
    this.recordStatus = const Value.absent(),
    this.confirmedData = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.nextSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.conflictServerData = const Value.absent(),
    this.conflictLocalData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rawInput = Value(rawInput);
  static Insertable<HealthRecord> custom({
    Expression<String>? id,
    Expression<String>? clientRecordId,
    Expression<String>? ownerUsername,
    Expression<String>? serverRecordId,
    Expression<String>? workerId,
    Expression<String>? rawInput,
    Expression<String>? inputLanguage,
    Expression<String>? audioPath,
    Expression<String>? aiStatus,
    Expression<String>? aiTranscript,
    Expression<String>? aiTranslation,
    Expression<String>? aiSuggestedData,
    Expression<String>? recordStatus,
    Expression<String>? confirmedData,
    Expression<String>? syncStatus,
    Expression<int>? syncAttempts,
    Expression<DateTime>? nextSyncAt,
    Expression<String>? lastSyncError,
    Expression<int>? serverVersion,
    Expression<String>? conflictServerData,
    Expression<String>? conflictLocalData,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientRecordId != null) 'client_record_id': clientRecordId,
      if (ownerUsername != null) 'owner_username': ownerUsername,
      if (serverRecordId != null) 'server_record_id': serverRecordId,
      if (workerId != null) 'worker_id': workerId,
      if (rawInput != null) 'raw_input': rawInput,
      if (inputLanguage != null) 'input_language': inputLanguage,
      if (audioPath != null) 'audio_path': audioPath,
      if (aiStatus != null) 'ai_status': aiStatus,
      if (aiTranscript != null) 'ai_transcript': aiTranscript,
      if (aiTranslation != null) 'ai_translation': aiTranslation,
      if (aiSuggestedData != null) 'ai_suggested_data': aiSuggestedData,
      if (recordStatus != null) 'record_status': recordStatus,
      if (confirmedData != null) 'confirmed_data': confirmedData,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (nextSyncAt != null) 'next_sync_at': nextSyncAt,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (serverVersion != null) 'server_version': serverVersion,
      if (conflictServerData != null)
        'conflict_server_data': conflictServerData,
      if (conflictLocalData != null) 'conflict_local_data': conflictLocalData,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthRecordsCompanion copyWith({
    Value<String>? id,
    Value<String?>? clientRecordId,
    Value<String?>? ownerUsername,
    Value<String?>? serverRecordId,
    Value<String?>? workerId,
    Value<String>? rawInput,
    Value<String?>? inputLanguage,
    Value<String?>? audioPath,
    Value<String>? aiStatus,
    Value<String?>? aiTranscript,
    Value<String?>? aiTranslation,
    Value<String?>? aiSuggestedData,
    Value<String>? recordStatus,
    Value<String?>? confirmedData,
    Value<String>? syncStatus,
    Value<int>? syncAttempts,
    Value<DateTime?>? nextSyncAt,
    Value<String?>? lastSyncError,
    Value<int?>? serverVersion,
    Value<String?>? conflictServerData,
    Value<String?>? conflictLocalData,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HealthRecordsCompanion(
      id: id ?? this.id,
      clientRecordId: clientRecordId ?? this.clientRecordId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      serverRecordId: serverRecordId ?? this.serverRecordId,
      workerId: workerId ?? this.workerId,
      rawInput: rawInput ?? this.rawInput,
      inputLanguage: inputLanguage ?? this.inputLanguage,
      audioPath: audioPath ?? this.audioPath,
      aiStatus: aiStatus ?? this.aiStatus,
      aiTranscript: aiTranscript ?? this.aiTranscript,
      aiTranslation: aiTranslation ?? this.aiTranslation,
      aiSuggestedData: aiSuggestedData ?? this.aiSuggestedData,
      recordStatus: recordStatus ?? this.recordStatus,
      confirmedData: confirmedData ?? this.confirmedData,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      nextSyncAt: nextSyncAt ?? this.nextSyncAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      serverVersion: serverVersion ?? this.serverVersion,
      conflictServerData: conflictServerData ?? this.conflictServerData,
      conflictLocalData: conflictLocalData ?? this.conflictLocalData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientRecordId.present) {
      map['client_record_id'] = Variable<String>(clientRecordId.value);
    }
    if (ownerUsername.present) {
      map['owner_username'] = Variable<String>(ownerUsername.value);
    }
    if (serverRecordId.present) {
      map['server_record_id'] = Variable<String>(serverRecordId.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (rawInput.present) {
      map['raw_input'] = Variable<String>(rawInput.value);
    }
    if (inputLanguage.present) {
      map['input_language'] = Variable<String>(inputLanguage.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (aiStatus.present) {
      map['ai_status'] = Variable<String>(aiStatus.value);
    }
    if (aiTranscript.present) {
      map['ai_transcript'] = Variable<String>(aiTranscript.value);
    }
    if (aiTranslation.present) {
      map['ai_translation'] = Variable<String>(aiTranslation.value);
    }
    if (aiSuggestedData.present) {
      map['ai_suggested_data'] = Variable<String>(aiSuggestedData.value);
    }
    if (recordStatus.present) {
      map['record_status'] = Variable<String>(recordStatus.value);
    }
    if (confirmedData.present) {
      map['confirmed_data'] = Variable<String>(confirmedData.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (nextSyncAt.present) {
      map['next_sync_at'] = Variable<DateTime>(nextSyncAt.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (conflictServerData.present) {
      map['conflict_server_data'] = Variable<String>(conflictServerData.value);
    }
    if (conflictLocalData.present) {
      map['conflict_local_data'] = Variable<String>(conflictLocalData.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthRecordsCompanion(')
          ..write('id: $id, ')
          ..write('clientRecordId: $clientRecordId, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('serverRecordId: $serverRecordId, ')
          ..write('workerId: $workerId, ')
          ..write('rawInput: $rawInput, ')
          ..write('inputLanguage: $inputLanguage, ')
          ..write('audioPath: $audioPath, ')
          ..write('aiStatus: $aiStatus, ')
          ..write('aiTranscript: $aiTranscript, ')
          ..write('aiTranslation: $aiTranslation, ')
          ..write('aiSuggestedData: $aiSuggestedData, ')
          ..write('recordStatus: $recordStatus, ')
          ..write('confirmedData: $confirmedData, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('nextSyncAt: $nextSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('conflictServerData: $conflictServerData, ')
          ..write('conflictLocalData: $conflictLocalData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HealthRecordsTable healthRecords = $HealthRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [healthRecords];
}

typedef $$HealthRecordsTableCreateCompanionBuilder =
    HealthRecordsCompanion Function({
      required String id,
      Value<String?> clientRecordId,
      Value<String?> ownerUsername,
      Value<String?> serverRecordId,
      Value<String?> workerId,
      required String rawInput,
      Value<String?> inputLanguage,
      Value<String?> audioPath,
      Value<String> aiStatus,
      Value<String?> aiTranscript,
      Value<String?> aiTranslation,
      Value<String?> aiSuggestedData,
      Value<String> recordStatus,
      Value<String?> confirmedData,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<DateTime?> nextSyncAt,
      Value<String?> lastSyncError,
      Value<int?> serverVersion,
      Value<String?> conflictServerData,
      Value<String?> conflictLocalData,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$HealthRecordsTableUpdateCompanionBuilder =
    HealthRecordsCompanion Function({
      Value<String> id,
      Value<String?> clientRecordId,
      Value<String?> ownerUsername,
      Value<String?> serverRecordId,
      Value<String?> workerId,
      Value<String> rawInput,
      Value<String?> inputLanguage,
      Value<String?> audioPath,
      Value<String> aiStatus,
      Value<String?> aiTranscript,
      Value<String?> aiTranslation,
      Value<String?> aiSuggestedData,
      Value<String> recordStatus,
      Value<String?> confirmedData,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<DateTime?> nextSyncAt,
      Value<String?> lastSyncError,
      Value<int?> serverVersion,
      Value<String?> conflictServerData,
      Value<String?> conflictLocalData,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$HealthRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRecordId => $composableBuilder(
    column: $table.clientRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverRecordId => $composableBuilder(
    column: $table.serverRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawInput => $composableBuilder(
    column: $table.rawInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputLanguage => $composableBuilder(
    column: $table.inputLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiStatus => $composableBuilder(
    column: $table.aiStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiTranscript => $composableBuilder(
    column: $table.aiTranscript,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiTranslation => $composableBuilder(
    column: $table.aiTranslation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiSuggestedData => $composableBuilder(
    column: $table.aiSuggestedData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordStatus => $composableBuilder(
    column: $table.recordStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmedData => $composableBuilder(
    column: $table.confirmedData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextSyncAt => $composableBuilder(
    column: $table.nextSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictServerData => $composableBuilder(
    column: $table.conflictServerData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictLocalData => $composableBuilder(
    column: $table.conflictLocalData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRecordId => $composableBuilder(
    column: $table.clientRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverRecordId => $composableBuilder(
    column: $table.serverRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawInput => $composableBuilder(
    column: $table.rawInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputLanguage => $composableBuilder(
    column: $table.inputLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiStatus => $composableBuilder(
    column: $table.aiStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiTranscript => $composableBuilder(
    column: $table.aiTranscript,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiTranslation => $composableBuilder(
    column: $table.aiTranslation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiSuggestedData => $composableBuilder(
    column: $table.aiSuggestedData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordStatus => $composableBuilder(
    column: $table.recordStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedData => $composableBuilder(
    column: $table.confirmedData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextSyncAt => $composableBuilder(
    column: $table.nextSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictServerData => $composableBuilder(
    column: $table.conflictServerData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictLocalData => $composableBuilder(
    column: $table.conflictLocalData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientRecordId => $composableBuilder(
    column: $table.clientRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverRecordId => $composableBuilder(
    column: $table.serverRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<String> get rawInput =>
      $composableBuilder(column: $table.rawInput, builder: (column) => column);

  GeneratedColumn<String> get inputLanguage => $composableBuilder(
    column: $table.inputLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get aiStatus =>
      $composableBuilder(column: $table.aiStatus, builder: (column) => column);

  GeneratedColumn<String> get aiTranscript => $composableBuilder(
    column: $table.aiTranscript,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiTranslation => $composableBuilder(
    column: $table.aiTranslation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiSuggestedData => $composableBuilder(
    column: $table.aiSuggestedData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordStatus => $composableBuilder(
    column: $table.recordStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confirmedData => $composableBuilder(
    column: $table.confirmedData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextSyncAt => $composableBuilder(
    column: $table.nextSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conflictServerData => $composableBuilder(
    column: $table.conflictServerData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conflictLocalData => $composableBuilder(
    column: $table.conflictLocalData,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HealthRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthRecordsTable,
          HealthRecord,
          $$HealthRecordsTableFilterComposer,
          $$HealthRecordsTableOrderingComposer,
          $$HealthRecordsTableAnnotationComposer,
          $$HealthRecordsTableCreateCompanionBuilder,
          $$HealthRecordsTableUpdateCompanionBuilder,
          (
            HealthRecord,
            BaseReferences<_$AppDatabase, $HealthRecordsTable, HealthRecord>,
          ),
          HealthRecord,
          PrefetchHooks Function()
        > {
  $$HealthRecordsTableTableManager(_$AppDatabase db, $HealthRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> clientRecordId = const Value.absent(),
                Value<String?> ownerUsername = const Value.absent(),
                Value<String?> serverRecordId = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                Value<String> rawInput = const Value.absent(),
                Value<String?> inputLanguage = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<String> aiStatus = const Value.absent(),
                Value<String?> aiTranscript = const Value.absent(),
                Value<String?> aiTranslation = const Value.absent(),
                Value<String?> aiSuggestedData = const Value.absent(),
                Value<String> recordStatus = const Value.absent(),
                Value<String?> confirmedData = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<DateTime?> nextSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<String?> conflictServerData = const Value.absent(),
                Value<String?> conflictLocalData = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthRecordsCompanion(
                id: id,
                clientRecordId: clientRecordId,
                ownerUsername: ownerUsername,
                serverRecordId: serverRecordId,
                workerId: workerId,
                rawInput: rawInput,
                inputLanguage: inputLanguage,
                audioPath: audioPath,
                aiStatus: aiStatus,
                aiTranscript: aiTranscript,
                aiTranslation: aiTranslation,
                aiSuggestedData: aiSuggestedData,
                recordStatus: recordStatus,
                confirmedData: confirmedData,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                nextSyncAt: nextSyncAt,
                lastSyncError: lastSyncError,
                serverVersion: serverVersion,
                conflictServerData: conflictServerData,
                conflictLocalData: conflictLocalData,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> clientRecordId = const Value.absent(),
                Value<String?> ownerUsername = const Value.absent(),
                Value<String?> serverRecordId = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                required String rawInput,
                Value<String?> inputLanguage = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<String> aiStatus = const Value.absent(),
                Value<String?> aiTranscript = const Value.absent(),
                Value<String?> aiTranslation = const Value.absent(),
                Value<String?> aiSuggestedData = const Value.absent(),
                Value<String> recordStatus = const Value.absent(),
                Value<String?> confirmedData = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<DateTime?> nextSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<String?> conflictServerData = const Value.absent(),
                Value<String?> conflictLocalData = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthRecordsCompanion.insert(
                id: id,
                clientRecordId: clientRecordId,
                ownerUsername: ownerUsername,
                serverRecordId: serverRecordId,
                workerId: workerId,
                rawInput: rawInput,
                inputLanguage: inputLanguage,
                audioPath: audioPath,
                aiStatus: aiStatus,
                aiTranscript: aiTranscript,
                aiTranslation: aiTranslation,
                aiSuggestedData: aiSuggestedData,
                recordStatus: recordStatus,
                confirmedData: confirmedData,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                nextSyncAt: nextSyncAt,
                lastSyncError: lastSyncError,
                serverVersion: serverVersion,
                conflictServerData: conflictServerData,
                conflictLocalData: conflictLocalData,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HealthRecordsTable, HealthRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HealthRecordsTable,
                    HealthRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthRecordsTable,
      HealthRecord,
      $$HealthRecordsTableFilterComposer,
      $$HealthRecordsTableOrderingComposer,
      $$HealthRecordsTableAnnotationComposer,
      $$HealthRecordsTableCreateCompanionBuilder,
      $$HealthRecordsTableUpdateCompanionBuilder,
      (
        HealthRecord,
        BaseReferences<_$AppDatabase, $HealthRecordsTable, HealthRecord>,
      ),
      HealthRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HealthRecordsTableTableManager get healthRecords =>
      $$HealthRecordsTableTableManager(_db, _db.healthRecords);
}
